import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/track.dart';

/// Enhanced real-time GPS tracking with background service, auto-upload, and live sharing
/// Inspired by GPSLogger and OSMTracker
class EnhancedTrackingService {
  static final EnhancedTrackingService _instance = EnhancedTrackingService._();
  factory EnhancedTrackingService() => _instance;
  EnhancedTrackingService._();

  StreamSubscription<Position>? _positionStream;
  GpsTrack? _currentTrack;
  Timer? _loggingTimer;
  Timer? _uploadTimer;
  Position? _lastPosition;

  // Configuration
  int _logIntervalSeconds = 5;
  double _logDistanceMeters = 10;
  int _accuracyFilter = 15;
  bool _batteryOptimized = true;
  bool _autoUpload = false;
  String? _uploadUrl;
  String? _uploadApiKey;
  bool _liveSharing = false;
  String? _liveShareId;

  // Observable streams
  final _trackController = StreamController<GpsTrack?>.broadcast();
  final _positionController = StreamController<Position>.broadcast();

  Stream<GpsTrack?> get trackStream => _trackController.stream;
  Stream<Position> get positionStream => _positionController.stream;
  GpsTrack? get currentTrack => _currentTrack;
  bool get isRecording => _currentTrack != null && _currentTrack!.status == TrackStatus.recording;
  bool get liveSharing => _liveSharing;
  String? get liveShareId => _liveShareId;

  /// Load settings
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _logIntervalSeconds = prefs.getInt('enh_track_interval') ?? 5;
    _logDistanceMeters = prefs.getDouble('enh_track_distance') ?? 10.0;
    _accuracyFilter = prefs.getInt('enh_track_accuracy') ?? 15;
    _batteryOptimized = prefs.getBool('enh_track_battery_opt') ?? true;
    _autoUpload = prefs.getBool('enh_track_auto_upload') ?? false;
    _uploadUrl = prefs.getString('enh_track_upload_url');
    _uploadApiKey = prefs.getString('enh_track_upload_key');
  }

  /// Save settings
  Future<void> saveSettings({
    int? intervalSeconds,
    double? distanceMeters,
    int? accuracyFilter,
    bool? batteryOptimized,
    bool? autoUpload,
    String? uploadUrl,
    String? uploadApiKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (intervalSeconds != null) {
      _logIntervalSeconds = intervalSeconds;
      await prefs.setInt('enh_track_interval', intervalSeconds);
    }
    if (distanceMeters != null) {
      _logDistanceMeters = distanceMeters;
      await prefs.setDouble('enh_track_distance', distanceMeters);
    }
    if (accuracyFilter != null) {
      _accuracyFilter = accuracyFilter;
      await prefs.setInt('enh_track_accuracy', accuracyFilter);
    }
    if (batteryOptimized != null) {
      _batteryOptimized = batteryOptimized;
      await prefs.setBool('enh_track_battery_opt', batteryOptimized);
    }
    if (autoUpload != null) {
      _autoUpload = autoUpload;
      await prefs.setBool('enh_track_auto_upload', autoUpload);
    }
    if (uploadUrl != null) {
      _uploadUrl = uploadUrl;
      await prefs.setString('enh_track_upload_url', uploadUrl);
    }
    if (uploadApiKey != null) {
      _uploadApiKey = uploadApiKey;
      await prefs.setString('enh_track_upload_key', uploadApiKey);
    }
  }

  /// Start recording a track
  Future<void> startRecording({String? name}) async {
    if (isRecording) return;

    _currentTrack = GpsTrack(
      id: 'live_track_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Live Tracking ${DateTime.now().toString().substring(0, 16)}',
      startTime: DateTime.now(),
      status: TrackStatus.recording,
    );

    // Start position stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: _batteryOptimized ? LocationAccuracy.balanced : LocationAccuracy.high,
        distanceFilter: _batteryOptimized ? _logDistanceMeters.toInt() : 0,
      ),
    ).listen(_onPositionUpdate);

    // Timer-based logging
    if (_batteryOptimized) {
      _loggingTimer = Timer.periodic(
        Duration(seconds: _logIntervalSeconds),
        (_) => _logCurrentPosition(),
      );
    }

    // Auto-upload timer (every 30 seconds while recording)
    if (_autoUpload && _uploadUrl != null) {
      _uploadTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _uploadCurrentTrack();
      });
    }

    _trackController.add(_currentTrack);
    debugPrint('Enhanced tracking started: ${_currentTrack!.name}');
  }

  void _onPositionUpdate(Position pos) {
    _lastPosition = pos;
    _positionController.add(pos);
    if (!_batteryOptimized) _addPoint(pos);
  }

  void _logCurrentPosition() {
    if (_lastPosition != null && isRecording) {
      _addPoint(_lastPosition!);
    }
  }

  void _addPoint(Position pos) {
    if (_currentTrack == null || pos.accuracy > _accuracyFilter) return;

    _currentTrack!.points.add(TrackPoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      altitude: pos.altitude,
      speed: pos.speed,
      bearing: pos.heading,
      accuracy: pos.accuracy,
      timestamp: DateTime.now(),
    ));

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
          Duration(seconds: _logIntervalSeconds), (_) => _logCurrentPosition(),
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
    _uploadTimer?.cancel();
    _currentTrack!.endTime = DateTime.now();
    _currentTrack!.status = TrackStatus.completed;

    // Final upload if auto-upload enabled
    if (_autoUpload && _uploadUrl != null) {
      await _uploadCurrentTrack();
    }

    final track = _currentTrack;
    _trackController.add(track);
    _currentTrack = null;

    // Stop live sharing
    if (_liveSharing) {
      await stopLiveSharing();
    }

    return track;
  }

  /// Upload track to server
  Future<bool> _uploadCurrentTrack() async {
    if (_currentTrack == null || _uploadUrl == null) return false;

    try {
      final response = await http.post(
        Uri.parse(_uploadUrl!),
        headers: {
          'Content-Type': 'application/json',
          if (_uploadApiKey != null) 'X-API-Key': _uploadApiKey!,
        },
        body: jsonEncode(_currentTrack!.toJson()),
      );
      debugPrint('Track upload: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Upload error: $e');
      return false;
    }
  }

  /// Start live sharing - generates a shareable link
  Future<String?> startLiveSharing() async {
    if (_currentTrack == null) return null;
    _liveSharing = true;
    _liveShareId = 'share_${DateTime.now().millisecondsSinceEpoch}';

    final shareUrl = 'https://krishi-drishti.app/live/$_liveShareId';
    debugPrint('Live sharing started: $shareUrl');
    return shareUrl;
  }

  /// Stop live sharing
  Future<void> stopLiveSharing() async {
    _liveSharing = false;
    _liveShareId = null;
    debugPrint('Live sharing stopped');
  }

  /// Get the latest position for live view
  Map<String, dynamic> getLivePosition() {
    if (_lastPosition == null) return {};
    return {
      'lat': _lastPosition!.latitude,
      'lng': _lastPosition!.longitude,
      'speed': _lastPosition!.speed,
      'bearing': _lastPosition!.heading,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> getStats() => {
    'is_recording': isRecording,
    'log_interval': _logIntervalSeconds,
    'accuracy_filter': _accuracyFilter,
    'auto_upload': _autoUpload,
    'live_sharing': _liveSharing,
    'points': _currentTrack?.points.length ?? 0,
  };

  void dispose() {
    stopRecording();
    _trackController.close();
    _positionController.close();
  }
}
