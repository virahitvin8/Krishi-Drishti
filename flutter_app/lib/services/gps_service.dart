import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

/// GPS service for real-time location tracking
/// Provides current position, address lookup, and location permissions
class GpsService {
  static final GpsService _instance = GpsService._();
  factory GpsService() => _instance;
  GpsService._();

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  /// Current user position
  Position? get currentPosition => _currentPosition;

  /// Check and request location permissions
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied');
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentLocation() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      );
      return _currentPosition;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Start listening to position updates (for real-time GPS tracking)
  void startListening(void Function(Position position) onUpdate) {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(onUpdate);
  }

  /// Stop listening to position updates
  void stopListening() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String> getAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude, longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return '${p.name}, ${p.locality}, ${p.administrativeArea}, ${p.country}'
            .replaceAll(', , ', ', ')
            .replaceAll(RegExp(r'^,\s*'), '');
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
    return '$latitude, $longitude';
  }

  /// Get distance between two points in meters
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Dispose
  void dispose() {
    stopListening();
  }
}
