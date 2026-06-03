import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/track.dart';

/// GPS Track Recording Service - inspired by OSMTracker and GPSLogger
/// Provides configurable background GPS logging with waypoints
class TrackService {
  static final TrackService _instance = TrackService._();
  factory TrackService() => _instance;
  TrackService._();

  StreamSubscription<Position>? _positionStream;
  GpsTrack? _currentTrack;
  Timer? _loggingTimer;
  Position? _lastPosition;

  // Configuration
  int _logIntervalSeconds = 5;     // Time between points
  double _logDistanceMeters = 10;  // Min distance between points
  int _accuracyFilter = 15;        // Discard points below this accuracy (meters)
  bool _batteryOptimized = true;

  // Observable
  final _trackController = StreamController<GpsTrack?>.broadcast();
  final _positionController = StreamController<Position>.broadcast();

  Stream<GpsTrack?> get trackStream => _trackController.stream;
  Stream<Position> get positionStream => _positionController.stream;

  GpsTrack? get currentTrack => _currentTrack;
  bool get isRecording => _currentTrack != null && _currentTrack!.status == TrackStatus.recording;

  double totalDistanceKm = 0;

  /// Load settings from storage
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _logIntervalSeconds = prefs.getInt('track_interval') ?? 5;
    _logDistanceMeters = (prefs.getDouble('track_distance') ?? 10.0);
    _accuracyFilter = prefs.getInt('track_accuracy') ?? 15;
    _batteryOptimized = prefs.getBool('track_battery_opt') ?? true;
  }

  /// Save settings
  Future<void> saveSettings({
    int? intervalSeconds,
    double? distanceMeters,
    int? accuracyFilter,
    bool? batteryOptimized,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (intervalSeconds != null) {
      _logIntervalSeconds = intervalSeconds;
      await prefs.setInt('track_interval', intervalSeconds);
    }
    if (distanceMeters != null) {
      _logDistanceMeters = distanceMeters;
      await prefs.setDouble('track_distance', distanceMeters);
    }
    if (accuracyFilter != null) {
      _accuracyFilter = accuracyFilter;
      await prefs.setInt('track_accuracy', accuracyFilter);
    }
    if (batteryOptimized != null) {
      _batteryOptimized = batteryOptimized;
      await prefs.setBool('track_battery_opt', batteryOptimized);
    }
  }

  /// Start recording a new GPS track
  Future<void> startRecording({String? name}) async {
    if (isRecording) return;

    _currentTrack = GpsTrack(
      id: 'track_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Field Visit ${DateTime.now().toString().substring(0, 16)}',
      startTime: DateTime.now(),
      status: TrackStatus.recording,
    );

    totalDistanceKm = 0;

    // Start position stream with battery-optimized settings
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: _batteryOptimized ? LocationAccuracy.medium : LocationAccuracy.high,
        distanceFilter: _batteryOptimized ? _logDistanceMeters.toInt() : 0,
        timeLimit: null,
      ),
    ).listen(_onPositionUpdate);

    // Timer-based logging if not using distance filter
    if (_batteryOptimized) {
      _loggingTimer = Timer.periodic(
        Duration(seconds: _logIntervalSeconds),
        (_) => _logCurrentPosition(),
      );
    }

    _trackController.add(_currentTrack);
    debugPrint('Track recording started: ${_currentTrack!.name}');
  }

  /// Handle position update from stream
  void _onPositionUpdate(Position pos) {
    _lastPosition = pos;
    _positionController.add(pos);

    // Only log if not using timer mode
    if (!_batteryOptimized) {
      _addPoint(pos);
    }
  }

  /// Log current position (for timer-based mode)
  void _logCurrentPosition() {
    if (_lastPosition != null && isRecording) {
      _addPoint(_lastPosition!);
    }
  }

  /// Add a track point
  void _addPoint(Position pos) {
    if (_currentTrack == null) return;

    // Accuracy filter
    if (pos.accuracy > _accuracyFilter) return;

    _currentTrack!.points.add(TrackPoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      altitude: pos.altitude,
      speed: pos.speed,
      bearing: pos.heading,
      accuracy: pos.accuracy,
      timestamp: DateTime.now(),
    ));

    // Calculate distance from last point
    if (_currentTrack!.points.length >= 2) {
      final prev = _currentTrack!.points[_currentTrack!.points.length - 2];
      final dist = Geolocator.distanceBetween(
        prev.latitude, prev.longitude,
        pos.latitude, pos.longitude,
      );
      totalDistanceKm += dist / 1000;
      _currentTrack!.totalDistanceKm = double.parse(
        totalDistanceKm.toStringAsFixed(3),
      );
    }

    // Calculate average speed
    if (_currentTrack!.points.length > 1 && pos.speed > 0) {
      final speeds = _currentTrack!.points
          .where((p) => p.speed != null && p.speed! > 0)
          .map((p) => p.speed!)
          .toList();
      if (speeds.isNotEmpty) {
        _currentTrack!.averageSpeedKmh = double.parse(
          (speeds.reduce((a, b) => a + b) / speeds.length * 3.6).toStringAsFixed(1),
        );
      }
    }

    _trackController.add(_currentTrack);
  }

  /// Pause recording
  void pauseRecording() {
    if (_currentTrack != null) {
      _currentTrack!.status = TrackStatus.paused;
      _loggingTimer?.cancel();
      _trackController.add(_currentTrack);
    }
  }

  /// Resume recording
  void resumeRecording() {
    if (_currentTrack != null) {
      _currentTrack!.status = TrackStatus.recording;
      if (_batteryOptimized) {
        _loggingTimer = Timer.periodic(
          Duration(seconds: _logIntervalSeconds),
          (_) => _logCurrentPosition(),
        );
      }
      _trackController.add(_currentTrack);
    }
  }

  /// Stop recording
  Future<GpsTrack?> stopRecording() async {
    if (_currentTrack == null) return null;

    _positionStream?.cancel();
    _loggingTimer?.cancel();
    _currentTrack!.endTime = DateTime.now();
    _currentTrack!.status = TrackStatus.completed;
    
    final track = _currentTrack;
    _trackController.add(track);
    _currentTrack = null;

    // Save track to storage
    await _saveTrack(track!);
    return track;
  }

  /// Add a waypoint to the current track
  Future<Waypoint> addWaypoint({
    required double latitude,
    required double longitude,
    String? name,
    String? description,
    String? category,
    List<String>? photoPaths,
    String? voiceNotePath,
  }) async {
    final wpt = Waypoint(
      id: 'wpt_${DateTime.now().millisecondsSinceEpoch}',
      latitude: latitude,
      longitude: longitude,
      altitude: _lastPosition?.altitude,
      name: name,
      description: description,
      category: category ?? 'observation',
      photoPaths: photoPaths ?? [],
      voiceNotePath: voiceNotePath,
      timestamp: DateTime.now(),
    );

    if (_currentTrack != null) {
      _currentTrack!.waypoints.add(wpt);
      _trackController.add(_currentTrack);
    }

    return wpt;
  }

  /// Save track to local storage
  Future<void> _saveTrack(GpsTrack track) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('saved_tracks') ?? [];
      saved.insert(0, jsonEncode(track.toMap()));
      if (saved.length > 50) saved.removeLast(); // Keep max 50 tracks
      await prefs.setStringList('saved_tracks', saved);
      
      // Save GPX for export
      await prefs.setString('gpx_${track.id}', track.toGpx());
    } catch (e) {
      debugPrint('Error saving track: $e');
    }
  }

  /// Get saved tracks list
  Future<List<Map<String, dynamic>>> getSavedTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_tracks') ?? [];
    return saved.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  /// Get GPX content for a track
  Future<String?> getTrackGpx(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gpx_$trackId');
  }

  /// Delete a saved track
  Future<void> deleteTrack(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_tracks') ?? [];
    saved.removeWhere((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return map['id'] == trackId;
    });
    await prefs.setStringList('saved_tracks', saved);
    await prefs.remove('gpx_$trackId');
  }

  /// Export track to file
  Future<File?> exportToGpx(String trackId, String outputPath) async {
    final gpx = await getTrackGpx(trackId);
    if (gpx == null) return null;
    
    final file = File('$outputPath/track_$trackId.gpx');
    await file.writeAsString(gpx);
    return file;
  }

  /// Get logging statistics
  Map<String, dynamic> getStats() {
    return {
      'total_distance_km': totalDistanceKm,
      'is_recording': isRecording,
      'log_interval': _logIntervalSeconds,
      'accuracy_filter': _accuracyFilter,
      'battery_optimized': _batteryOptimized,
    };
  }

  void dispose() {
    _positionStream?.cancel();
    _loggingTimer?.cancel();
    _trackController.close();
    _positionController.close();
  }
}
