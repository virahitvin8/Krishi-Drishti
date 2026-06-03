import 'dart:math' as math;

/// Measurement result for area, distance, or elevation
class FieldMeasurement {
  final String id;
  final String name;
  final double value;
  final MeasurementUnit unit;
  final MeasurementType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  FieldMeasurement({
    required this.id,
    required this.name,
    required this.value,
    required this.unit,
    required this.type,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formatted {
    final v = value.toStringAsFixed(2);
    switch (unit) {
      case MeasurementUnit.meters: return '${v}m';
      case MeasurementUnit.kilometers: return '${v}km';
      case MeasurementUnit.hectares: return '${v} ha';
      case MeasurementUnit.acres: return '${v} acres';
      case MeasurementUnit.squareMeters: return '${v} m²';
      case MeasurementUnit.degrees: return '${v}°';
      case MeasurementUnit.metersPerSecond: return '${v} m/s';
      case MeasurementUnit.kilometersPerHour: return '${v} km/h';
    }
  }
}

enum MeasurementType { distance, area, elevation, perimeter, bearing }
enum MeasurementUnit { meters, kilometers, hectares, acres, squareMeters, degrees, metersPerSecond, kilometersPerHour }

/// Coordinate conversion utilities
class CoordinateConverter {
  /// Decimal degrees to DMS (Degrees Minutes Seconds)
  static String toDms(double decimalDegrees, bool isLatitude) {
    final dir = isLatitude
        ? (decimalDegrees >= 0 ? 'N' : 'S')
        : (decimalDegrees >= 0 ? 'E' : 'W');
    final abs = decimalDegrees.abs();
    final degrees = abs.floor();
    final minutesFull = (abs - degrees) * 60;
    final minutes = minutesFull.floor();
    final seconds = (minutesFull - minutes) * 60;
    return '$degrees°$minutes\'${seconds.toStringAsFixed(1)}\"$dir';
  }

  /// Decimal degrees to MGRS (simplified)
  static String toMgrs(double lat, double lng) {
    final zone = ((lng + 180) / 6).ceil();
    final latBand = 'CDEFGHJKLMNPQRSTUVWXX'[((lat + 80) / 8).floor().clamp(0, 19)];
    final easting = ((lng + 180) % 6) / 6 * 100000;
    final northing = ((lat + 80) % 8) / 8 * 100000;
    return '${zone}$latBand ${easting.toStringAsFixed(0)} ${northing.toStringAsFixed(0)}';
  }

  /// Decimal degrees to UTM
  static ({int zone, double easting, double northing, bool isNorth}) toUtm(double lat, double lng) {
    final zone = ((lng + 180) / 6).ceil();
    final isNorth = lat >= 0;
    final centralMeridian = (zone - 1) * 6 - 180 + 3;
    return (zone: zone, easting: 500000, northing: 0, isNorth: isNorth);
  }

  /// Calculate area of polygon in hectares using Shoelace formula
  static double polygonAreaHectares(List<({double lat, double lng})> polygon) {
    if (polygon.length < 3) return 0;
    
    // Convert to planar coordinates using equirectangular approximation
    double area = 0;
    final n = polygon.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final lat1 = polygon[i].lat * math.pi / 180;
      final lon1 = polygon[i].lng * math.pi / 180;
      final lat2 = polygon[j].lat * math.pi / 180;
      final lon2 = polygon[j].lng * math.pi / 180;
      
      // Spherical area contribution
      area += (lon2 - lon1) * (2 + math.sin(lat1) + math.sin(lat2));
    }
    
    // Area in square meters (R² = 6371000²)
    final areaSqMeters = (6371000 * 6371000 / 2) * area.abs();
    return areaSqMeters / 10000; // Convert to hectares
  }

  /// Calculate perimeter of polygon in meters
  static double polygonPerimeterMeters(List<({double lat, double lng})> polygon) {
    double perimeter = 0;
    final n = polygon.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      perimeter += haversine(polygon[i].lat, polygon[i].lng, polygon[j].lat, polygon[j].lng);
    }
    return perimeter;
  }

  static double haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Calculate bearing between two points in degrees
  static double bearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2 * math.pi / 180);
    final x = math.cos(lat1 * math.pi / 180) * math.sin(lat2 * math.pi / 180) -
        math.sin(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.cos(dLon);
    final brng = math.atan2(y, x) * 180 / math.pi;
    return (brng + 360) % 360;
  }
}
