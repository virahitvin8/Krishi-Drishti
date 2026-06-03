import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/measurement.dart';

/// Measurement Cockpit service - inspired by GPS Cockpit
/// Area/distance measurement, elevation profiles, coordinate conversion, compass
class MeasurementService {
  static final MeasurementService _instance = MeasurementService._();
  factory MeasurementService() => _instance;
  MeasurementService._();

  final List<FieldMeasurement> _history = [];
  Position? _lastPosition;

  // Observable
  final _measurementController = StreamController<FieldMeasurement>.broadcast();
  final _historyController = StreamController<List<FieldMeasurement>>.broadcast();

  Stream<FieldMeasurement> get measurementStream => _measurementController.stream;
  Stream<List<FieldMeasurement>> get historyStream => _historyController.stream;

  /// Measure area of a polygon in hectares
  FieldMeasurement measureArea(List<({double lat, double lng})> polygon, {String name = 'Field Area'}) {
    final hectares = CoordinateConverter.polygonAreaHectares(polygon);
    final acres = hectares * 2.47105;
    final perimeter = CoordinateConverter.polygonPerimeterMeters(polygon);

    final measurement = FieldMeasurement(
      id: 'area_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      value: hectares,
      unit: MeasurementUnit.hectares,
      type: MeasurementType.area,
      metadata: {
        'acres': double.parse(acres.toStringAsFixed(2)),
        'perimeterMeters': double.parse(perimeter.toStringAsFixed(1)),
        'points': polygon.length,
      },
    );

    _history.add(measurement);
    _measurementController.add(measurement);
    _saveHistory();
    return measurement;
  }

  /// Measure distance between two points
  FieldMeasurement measureDistance(
    double lat1, double lon1, double lat2, double lon2,
    {String name = 'Distance'},
  ) {
    final meters = CoordinateConverter._haversine(lat1, lon1, lat2, lon2);
    final bearing = CoordinateConverter.bearing(lat1, lon1, lat2, lon2);

    final measurement = FieldMeasurement(
      id: 'dist_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      value: meters >= 1000 ? meters / 1000 : meters,
      unit: meters >= 1000 ? MeasurementUnit.kilometers : MeasurementUnit.meters,
      type: MeasurementType.distance,
      metadata: {
        'bearing': double.parse(bearing.toStringAsFixed(1)),
        'startLat': lat1,
        'startLng': lon1,
        'endLat': lat2,
        'endLng': lon2,
      },
    );

    _history.add(measurement);
    _measurementController.add(measurement);
    _saveHistory();
    return measurement;
  }

  /// Calculate elevation profile from a list of points
  List<({double distance, double elevation})> calculateElevationProfile(
    List<({double lat, double lng, double? elevation})> points,
  ) {
    if (points.length < 2) return [];

    final profile = <({double distance, double elevation})>[];
    double totalDist = 0;

    for (int i = 0; i < points.length; i++) {
      if (i > 0) {
        totalDist += CoordinateConverter._haversine(
          points[i - 1].lat, points[i - 1].lng,
          points[i].lat, points[i].lng,
        );
      }
      profile.add((distance: totalDist, elevation: points[i].elevation ?? 0));
    }

    return profile;
  }

  /// Get coordinate in multiple formats
  Map<String, String> formatCoordinate(double lat, double lng) {
    return {
      'dd': '${lat.toStringAsFixed(6)}°, ${lng.toStringAsFixed(6)}°',
      'dms': '${CoordinateConverter.toDms(lat, true)} ${CoordinateConverter.toDms(lng, false)}',
      'mgrs': CoordinateConverter.toMgrs(lat, lng),
      'utm': _formatUtm(lat, lng),
    };
  }

  String _formatUtm(double lat, double lng) {
    final utm = CoordinateConverter.toUtm(lat, lng);
    final hemisphere = utm.isNorth ? 'N' : 'S';
    return '${utm.zone}$hemisphere ${utm.easting.toStringAsFixed(0)}m E / ${utm.northing.toStringAsFixed(0)}m N';
  }

  /// Get current heading/compass direction
  String getHeadingDirection(double bearingDegrees) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                        'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((bearingDegrees + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  /// Load measurement history
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('measurement_history') ?? [];
      _history.clear();
      _history.addAll(saved.map((s) {
        final map = jsonDecode(s) as Map<String, dynamic>;
        return FieldMeasurement(
          id: map['id'],
          name: map['name'],
          value: (map['value'] as num).toDouble(),
          unit: MeasurementUnit.values.firstWhere((e) => e.name == map['unit']),
          type: MeasurementType.values.firstWhere((e) => e.name == map['type']),
          timestamp: DateTime.parse(map['timestamp']),
          metadata: map['metadata'] as Map<String, dynamic>?,
        );
      }));
      _historyController.add(List.from(_history));
    } catch (e) {
      debugPrint('Error loading measurement history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _history.map((m) => jsonEncode({
        'id': m.id, 'name': m.name, 'value': m.value,
        'unit': m.unit.name, 'type': m.type.name,
        'timestamp': m.timestamp.toIso8601String(),
        'metadata': m.metadata,
      })).toList();
      await prefs.setStringList('measurement_history', data);
    } catch (e) {
      debugPrint('Error saving measurement history: $e');
    }
  }

  /// Clear history
  Future<void> clearHistory() async {
    _history.clear();
    _historyController.add([]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('measurement_history');
  }

  List<FieldMeasurement> get history => List.unmodifiable(_history);

  void dispose() {
    _measurementController.close();
    _historyController.close();
  }
}
