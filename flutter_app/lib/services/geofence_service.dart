import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/geofence.dart';

/// Geofencing service - inspired by GPSTest, OSMTracker
/// Monitors device location against field boundary fences and triggers actions
class GeofenceService {
  static final GeofenceService _instance = GeofenceService._();
  factory GeofenceService() => _instance;
  GeofenceService._();

  final List<Geofence> _fences = [];
  StreamSubscription<Position>? _positionStream;
  Timer? _checkTimer;
  Position? _lastPosition;

  // State tracking for enter/exit detection
  final Map<String, bool> _insideFence = {};
  final Map<String, DateTime> _dwellStart = {};

  // Broadcast streams
  final _fenceController = StreamController<List<Geofence>>.broadcast();
  final _eventController = StreamController<GeofenceEvent>.broadcast();

  Stream<List<Geofence>> get fenceStream => _fenceController.stream;
  Stream<GeofenceEvent> get eventStream => _eventController.stream;
  List<Geofence> get fences => List.unmodifiable(_fences);

  /// Load saved geofences from storage
  Future<void> loadFences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('geofences') ?? [];
      _fences.clear();
      for (final s in saved) {
        _fences.add(Geofence.fromJson(s));
      }
      _fenceController.add(List.from(_fences));
    } catch (e) {
      debugPrint('Error loading geofences: $e');
    }
  }

  /// Save all geofences to storage
  Future<void> _saveFences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _fences.map((f) => jsonEncode(f.toMap())).toList();
      await prefs.setStringList('geofences', data);
    } catch (e) {
      debugPrint('Error saving geofences: $e');
    }
  }

  /// Add a new geofence
  Future<void> addFence(Geofence fence) async {
    _fences.add(fence);
    _insideFence[fence.id] = false;
    _fenceController.add(List.from(_fences));
    await _saveFences();
  }

  /// Update an existing geofence
  Future<void> updateFence(Geofence fence) async {
    final index = _fences.indexWhere((f) => f.id == fence.id);
    if (index >= 0) {
      _fences[index] = fence;
      _fenceController.add(List.from(_fences));
      await _saveFences();
    }
  }

  /// Remove a geofence
  Future<void> removeFence(String id) async {
    _fences.removeWhere((f) => f.id == id);
    _insideFence.remove(id);
    _dwellStart.remove(id);
    _fenceController.add(List.from(_fences));
    await _saveFences();
  }

  /// Start geofence monitoring
  void startMonitoring() {
    _checkTimer?.cancel();
    _positionStream?.cancel();

    // Check position every 5 seconds for geofence state
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_lastPosition != null) {
        _checkFences(_lastPosition!.latitude, _lastPosition!.longitude);
      }
    });

    // Listen to position updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Check every 10m movement
      ),
    ).listen((pos) {
      _lastPosition = pos;
      _checkFences(pos.latitude, pos.longitude);
    });

    debugPrint('Geofence monitoring started');
  }

  /// Check all fences against current position
  void _checkFences(double lat, double lng) {
    final now = DateTime.now();

    for (final fence in _fences) {
      if (!fence.enabled) continue;

      final isInside = fence.containsPoint(lat, lng);
      final wasInside = _insideFence[fence.id] ?? false;

      if (isInside && !wasInside) {
        // Enter transition
        _dwellStart[fence.id] = now;

        // Check dwell time
        Timer(Duration(milliseconds: (fence.dwellTimeSeconds * 1000).toInt()), () {
          final dwellStart = _dwellStart[fence.id];
          if (dwellStart != null && DateTime.now().difference(dwellStart).inSeconds >= fence.dwellTimeSeconds.toInt()) {
            if (_insideFence[fence.id] == true) {
              _triggerEvent(fence, GeofenceTransition.enter, lat, lng);
              _executeActions(fence, GeofenceTransition.enter, lat, lng);
            }
          }
        });

      } else if (!isInside && wasInside) {
        // Exit transition
        _dwellStart.remove(fence.id);
        _triggerEvent(fence, GeofenceTransition.exit, lat, lng);
        _executeActions(fence, GeofenceTransition.exit, lat, lng);
      }

      _insideFence[fence.id] = isInside;

      // Check for dwell (still inside after dwell time)
      if (isInside && wasInside && _dwellStart.containsKey(fence.id)) {
        final dwellStart = _dwellStart[fence.id]!;
        if (now.difference(dwellStart).inSeconds >= fence.dwellTimeSeconds.toInt()) {
          _dwellStart.remove(fence.id); // Prevent duplicate
        }
      }
    }
  }

  /// Record and broadcast a geofence event
  void _triggerEvent(Geofence fence, GeofenceTransition transition, double lat, double lng) {
    fence.lastTriggered = DateTime.now();
    final event = GeofenceEvent(
      geofenceId: fence.id,
      geofenceName: fence.name,
      transition: transition,
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
    );
    _eventController.add(event);
    debugPrint('Geofence event: ${fence.name} - ${transition.name}');
  }

  /// Execute the configured actions for a geofence trigger
  void _executeActions(Geofence fence, GeofenceTransition transition, double lat, double lng) {
    for (final action in fence.actions) {
      switch (action) {
        case GeofenceAction.notify:
          debugPrint('🔔 NOTIFICATION: ${fence.name} - ${transition.name}');
          break;
        case GeofenceAction.startRecording:
          debugPrint('⏺️ START RECORDING: ${fence.name}');
          break;
        case GeofenceAction.stopRecording:
          debugPrint('⏹️ STOP RECORDING: ${fence.name}');
          break;
        case GeofenceAction.takePhoto:
          debugPrint('📸 TAKE PHOTO at: $lat, $lng');
          break;
        case GeofenceAction.sendAlert:
          debugPrint('🚨 SEND ALERT: ${fence.name} - ${transition.name}');
          break;
        case GeofenceAction.logEvent:
          debugPrint('📝 LOG: ${fence.name} - ${transition.name} at $lat, $lng');
          break;
      }
    }
  }

  /// Get a fence by ID
  Geofence? getFenceById(String id) {
    try {
      return _fences.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check if current position is inside any fence
  bool isInsideAnyFence(Position position) {
    return _fences.any((f) => f.enabled && f.containsPoint(position.latitude, position.longitude));
  }

  /// Get fences near a position
  List<Geofence> getFencesNear(double lat, double lng, double radiusMeters) {
    return _fences.where((f) {
      if (f.type == GeofenceType.circular && f.latitude != null && f.longitude != null) {
        final dist = Geofence.haversine(lat, lng, f.latitude!, f.longitude!);
        return dist <= radiusMeters + (f.radiusMeters ?? 0);
      }
      return f.containsPoint(lat, lng);
    }).toList();
  }

  /// Stop monitoring
  void stopMonitoring() {
    _checkTimer?.cancel();
    _positionStream?.cancel();
    _checkTimer = null;
    _positionStream = null;
  }

  /// Dispose
  void dispose() {
    stopMonitoring();
    _fenceController.close();
    _eventController.close();
  }
}
