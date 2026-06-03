import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/satellite_scene.dart';

/// Satellite imagery overlay service - inspired by image-satellite-visualizer
/// Provides satellite scene lookup, NDVI overlay, and historical comparison
class SatelliteOverlayService {
  static final SatelliteOverlayService _instance = SatelliteOverlayService._();
  factory SatelliteOverlayService() => _instance;
  SatelliteOverlayService._();

  final List<SatelliteScene> _availableScenes = [];
  SatelliteScene? _selectedScene;

  // Streams
  final _scenesController = StreamController<List<SatelliteScene>>.broadcast();
  final _selectedController = StreamController<SatelliteScene?>.broadcast();

  Stream<List<SatelliteScene>> get scenesStream => _scenesController.stream;
  Stream<SatelliteScene?> get selectedStream => _selectedController.stream;
  List<SatelliteScene> get availableScenes => List.unmodifiable(_availableScenes);
  SatelliteScene? get selectedScene => _selectedScene;

  /// Load available satellite scenes for a location
  /// In production, this would fetch from CDSE (Copernicus Data Space Ecosystem) API
  Future<List<SatelliteScene>> loadScenesForLocation(double lat, double lng, {int daysBack = 30}) async {
    _availableScenes.clear();

    // Generate simulated scenes with realistic properties
    final now = DateTime.now();
    final random = (lat * 1000 + lng * 1000).abs().toInt();

    // Sentinel-2 scenes (every 5 days)
    for (int i = 0; i < daysBack ~/ 5; i++) {
      final date = now.subtract(Duration(days: i * 5));
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) continue;

      final cloudCover = ((random + i * 7) % 100) / 100.0;
      if (cloudCover > 0.8) continue; // Skip very cloudy scenes

      _availableScenes.add(SatelliteScene(
        id: 'S2A_${date.toIso8601String().substring(0, 10)}',
        source: SatelliteSource.sentinel2,
        acquisitionDate: date,
        latitude: lat,
        longitude: lng,
        cloudCover: double.parse((cloudCover * 100).toStringAsFixed(1)),
        ndviMin: double.parse(((0.1 + (random + i * 3) % 40 / 100)).toStringAsFixed(2)),
        ndviMax: double.parse(((0.5 + (random + i * 7) % 40 / 100)).toStringAsFixed(2)),
        ndviMean: double.parse(((0.25 + (random + i * 5) % 30 / 100)).toStringAsFixed(2)),
        available: cloudCover < 0.6,
        metadata: {
          'resolution': '10m',
          'bands': ['B2', 'B3', 'B4', 'B8'],
          'processingLevel': 'L2A',
        },
      ));
    }

    // Landsat 8/9 scenes (every 16 days)
    for (int i = 0; i < daysBack ~/ 16; i++) {
      final date = now.subtract(Duration(days: i * 16));
      final source = i % 2 == 0 ? SatelliteSource.landsat8 : SatelliteSource.landsat9;
      final cloudCover = ((random + i * 13) % 100) / 100.0;
      if (cloudCover > 0.7) continue;

      _availableScenes.add(SatelliteScene(
        id: 'LC${source == SatelliteSource.landsat8 ? '08' : '09'}_${date.toIso8601String().substring(0, 10)}',
        source: source,
        acquisitionDate: date,
        latitude: lat,
        longitude: lng,
        cloudCover: double.parse((cloudCover * 100).toStringAsFixed(1)),
        ndviMin: double.parse(((0.15 + (random + i * 11) % 35 / 100)).toStringAsFixed(2)),
        ndviMax: double.parse(((0.55 + (random + i * 9) % 35 / 100)).toStringAsFixed(2)),
        ndviMean: double.parse(((0.3 + (random + i * 7) % 25 / 100)).toStringAsFixed(2)),
        available: cloudCover < 0.5,
        metadata: {
          'resolution': '30m',
          'bands': ['B2', 'B3', 'B4', 'B5'],
          'processingLevel': 'L2SP',
        },
      ));
    }

    // Sort newest first
    _availableScenes.sort((a, b) => b.acquisitionDate.compareTo(a.acquisitionDate));
    _scenesController.add(List.from(_availableScenes));
    return _availableScenes;
  }

  /// Select a specific scene for overlay
  void selectScene(String sceneId) {
    try {
      _selectedScene = _availableScenes.firstWhere((s) => s.id == sceneId);
      _selectedController.add(_selectedScene);
    } catch (_) {
      debugPrint('Scene $sceneId not found');
    }
  }

  /// Get scenes from a specific satellite source
  List<SatelliteScene> getScenesBySource(SatelliteSource source) {
    return _availableScenes.where((s) => s.source == source).toList();
  }

  /// Get the most recent clear scene
  SatelliteScene? getLatestClearScene({double maxCloudCover = 20}) {
    try {
      return _availableScenes.firstWhere((s) => s.cloudCover <= maxCloudCover && s.available);
    } catch (_) {
      return _availableScenes.isNotEmpty ? _availableScenes.first : null;
    }
  }

  /// Compare NDVI between two scenes
  Map<String, dynamic>? compareScenes(String sceneId1, String sceneId2) {
    SatelliteScene? s1, s2;
    try {
      s1 = _availableScenes.firstWhere((s) => s.id == sceneId1);
      s2 = _availableScenes.firstWhere((s) => s.id == sceneId2);
    } catch (_) {
      return null;
    }

    if (s1.ndviMean == null || s2.ndviMean == null) return null;

    final change = s2.ndviMean! - s1.ndviMean!;
    final daysBetween = s2.acquisitionDate.difference(s1.acquisitionDate).inDays;

    return {
      'scene1': s1.id,
      'scene1Date': s1.acquisitionDate.toIso8601String(),
      'scene1Ndvi': s1.ndviMean,
      'scene2': s2.id,
      'scene2Date': s2.acquisitionDate.toIso8601String(),
      'scene2Ndvi': s2.ndviMean,
      'change': double.parse(change.toStringAsFixed(3)),
      'changePercent': double.parse((change / (s1.ndviMean! + 0.001) * 100).toStringAsFixed(1)),
      'daysBetween': daysBetween,
      'trend': change > 0.05 ? 'Improving' : (change < -0.05 ? 'Declining' : 'Stable'),
    };
  }

  /// Clear selection
  void clearSelection() {
    _selectedScene = null;
    _selectedController.add(null);
  }

  void dispose() {
    _scenesController.close();
    _selectedController.close();
  }
}
