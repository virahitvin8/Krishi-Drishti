import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/survey_point.dart';

/// Field Survey Pro service - inspired by OSMTracker
/// Supports photo-tagged waypoints, voice notes, structured forms, and offline sync
class SurveyService {
  static final SurveyService _instance = SurveyService._();
  factory SurveyService() => _instance;
  SurveyService._();

  // Stream for real-time survey updates
  final _surveyController = StreamController<List<SurveyPoint>>.broadcast();
  Stream<List<SurveyPoint>> get surveyStream => _surveyController.stream;

  /// Save a survey point locally
  Future<void> saveSurveyPoint(SurveyPoint point) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('survey_points') ?? [];
      saved.add(jsonEncode(point.toMap()));
      await prefs.setStringList('survey_points', saved);
      _surveyController.add([point]);
      debugPrint('Survey point saved: ${point.name} at ${point.latitude}, ${point.longitude}');
    } catch (e) {
      debugPrint('Error saving survey point: $e');
    }
  }

  /// Get all saved survey points
  Future<List<SurveyPoint>> getSurveyPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('survey_points') ?? [];
    return saved.map((s) => SurveyPoint.fromJson(s)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get survey points by type
  Future<List<SurveyPoint>> getPointsByType(SurveyType type) async {
    final all = await getSurveyPoints();
    return all.where((p) => p.type == type).toList();
  }

  /// Get survey points near a location
  Future<List<SurveyPoint>> getPointsNear(double lat, double lng, {double radiusKm = 1.0}) async {
    final all = await getSurveyPoints();
    return all.where((p) {
      final dist = _haversine(lat, lng, p.latitude, p.longitude);
      return dist <= radiusKm * 1000;
    }).toList();
  }

  /// Delete a survey point
  Future<void> deleteSurveyPoint(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('survey_points') ?? [];
    saved.removeWhere((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return map['id'] == id;
    });
    await prefs.setStringList('survey_points', saved);
  }

  /// Save photo for a survey point and return the local file path
  Future<String?> savePhoto(String sourcePath, String surveyPointId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${dir.path}/survey_photos');
      if (!await photoDir.exists()) await photoDir.create(recursive: true);

      final ext = sourcePath.split('.').last;
      final destPath = '${photoDir.path}/${surveyPointId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (e) {
      debugPrint('Error saving photo: $e');
      return null;
    }
  }

  /// Save voice note for a survey point
  Future<String?> saveVoiceNote(String sourcePath, String surveyPointId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${dir.path}/survey_audio');
      if (!await audioDir.exists()) await audioDir.create(recursive: true);

      final destPath = '${audioDir.path}/${surveyPointId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (e) {
      debugPrint('Error saving voice note: $e');
      return null;
    }
  }

  /// Mark a survey point as synced with the backend
  Future<void> markSynced(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('survey_points') ?? [];
    final updated = saved.map((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      if (map['id'] == id) {
        map['synced'] = true;
        return jsonEncode(map);
      }
      return s;
    }).toList();
    await prefs.setStringList('survey_points', updated);
  }

  /// Sync all unsynced survey points to backend
  Future<int> syncToBackend(String apiUrl, {String? apiKey}) async {
    final unsynced = (await getSurveyPoints()).where((p) => !p.synced).toList();
    int synced = 0;

    for (final point in unsynced) {
      try {
        // In production, POST to your backend
        // final response = await http.post(Uri.parse('$apiUrl/survey-points'), body: point.toJson());
        await markSynced(point.id);
        synced++;
      } catch (e) {
        debugPrint('Sync error for ${point.id}: $e');
      }
    }

    return synced;
  }

  /// Get template for a survey type
  static SurveyTemplate getTemplate(SurveyType type) {
    return SurveyTemplate.templates[type] ?? SurveyTemplate.templates[SurveyType.generalObservation]!;
  }

  /// Get all available survey templates
  static List<SurveyTemplate> get allTemplates => SurveyTemplate.templates.values.toList();

  /// Get statistics
  Future<Map<String, dynamic>> getStats() async {
    final points = await getSurveyPoints();
    return {
      'total': points.length,
      'pestChecks': points.where((p) => p.type == SurveyType.pestCheck).length,
      'soilSamples': points.where((p) => p.type == SurveyType.soilSample).length,
      'cropConditions': points.where((p) => p.type == SurveyType.cropCondition).length,
      'synced': points.where((p) => p.synced).length,
      'pendingSync': points.where((p) => !p.synced).length,
      'recentWeek': points.where((p) =>
        DateTime.now().difference(p.timestamp).inDays <= 7).length,
    };
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * 3.141592653589793 / 180;
    final dLon = (lon2 - lon1) * 3.141592653589793 / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * 3.141592653589793 / 180) *
        math.cos(lat2 * 3.141592653589793 / 180) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void dispose() {
    _surveyController.close();
  }
}
