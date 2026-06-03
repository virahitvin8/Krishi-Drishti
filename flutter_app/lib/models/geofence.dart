import 'dart:convert';

/// Geofence types
enum GeofenceType {
  circular,   // Radius-based fence
  polygonal,  // Custom polygon fence
}

/// Trigger action when geofence boundary is crossed
enum GeofenceAction {
  notify,          // Send push notification
  startRecording,  // Auto-start GPS track recording
  stopRecording,   // Auto-stop GPS track recording
  takePhoto,       // Prompt to take a photo
  sendAlert,       // Send alert to server
  logEvent,        // Just log the event
}

/// Direction of boundary crossing
enum GeofenceTransition {
  enter,
  exit,
  dwell,
}

/// A geofence boundary around a field or area of interest
class Geofence {
  final String id;
  final String name;
  final String? description;
  final GeofenceType type;
  final double? latitude;       // Center lat (circular)
  final double? longitude;      // Center lng (circular)
  final double? radiusMeters;   // Radius in meters (circular)
  final List<({double lat, double lng})>? polygon; // Polygon vertices
  final List<GeofenceAction> actions;
  final double dwellTimeSeconds; // How long to wait before triggering
  final bool enabled;
  final DateTime createdAt;
  DateTime? lastTriggered;

  Geofence({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.latitude,
    this.longitude,
    this.radiusMeters,
    this.polygon,
    this.actions = const [GeofenceAction.notify],
    this.dwellTimeSeconds = 10,
    this.enabled = true,
    DateTime? createdAt,
    this.lastTriggered,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Check if a point is inside this geofence
  bool containsPoint(double lat, double lng) {
    if (!enabled) return false;

    if (type == GeofenceType.circular && latitude != null && longitude != null && radiusMeters != null) {
      final distance = haversine(lat, lng, latitude!, longitude!);
      return distance <= radiusMeters!;
    }

    if (type == GeofenceType.polygonal && polygon != null && polygon!.length >= 3) {
      return _pointInPolygon(lat, lng, polygon!);
    }

    return false;
  }

  /// Get distance from center (for circular) or nearest edge (for polygonal)
  double distanceToBoundary(double lat, double lng) {
    if (type == GeofenceType.circular && latitude != null && longitude != null) {
      return haversine(lat, lng, latitude!, longitude!);
    }
    if (type == GeofenceType.polygonal && polygon != null) {
      double minDist = double.infinity;
      for (int i = 0; i < polygon!.length; i++) {
        final j = (i + 1) % polygon!.length;
        final dist = _pointToSegmentDistance(
          lat, lng,
          polygon![i].lat, polygon![i].lng,
          polygon![j].lat, polygon![j].lng,
        );
        if (dist < minDist) minDist = dist;
      }
      return minDist;
    }
    return double.infinity;
  }

  /// Haversine distance in meters
  static double haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = _sinSq(dLat / 2) +
        _cos(lat1) * _cos(lat2) * _sinSq(dLon / 2);
    return R * 2 * _asin(_sqrt(a));
  }

  static double _toRadians(double deg) => deg * 3.141592653589793 / 180;
  static double _sinSq(double x) { final s = _sin(x); return s * s; }
  static double _sin(double x) => x - x*x*x/6 + x*x*x*x*x/120;
  static double _cos(double x) => 1 - x*x/2 + x*x*x*x/24;
  static double _asin(double x) => x + x*x*x/6 + x*x*x*x*x*3/40;
  static double _sqrt(double x) => x < 0 ? 0 : x > 1 ? 1 : x;

  /// Point-in-polygon using ray casting
  static bool _pointInPolygon(double lat, double lng, List<({double lat, double lng})> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if ((polygon[i].lng > lng) != (polygon[j].lng > lng) &&
          lat < (polygon[j].lat - polygon[i].lat) * (lng - polygon[i].lng) /
              (polygon[j].lng - polygon[i].lng) + polygon[i].lat) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Minimum distance from point to line segment
  static double _pointToSegmentDistance(
    double px, double py,
    double ax, double ay,
    double bx, double by,
  ) {
    final dx = bx - ax;
    final dy = by - ay;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return haversine(px, py, ax, ay);

    var t = ((px - ax) * dx + (py - ay) * dy) / lenSq;
    t = t.clamp(0.0, 1.0);

    final projX = ax + t * dx;
    final projY = ay + t * dy;
    return haversine(px, py, projX, projY);
  }

  /// Serialize to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'polygon': polygon?.map((p) => {'lat': p.lat, 'lng': p.lng}).toList(),
      'actions': actions.map((a) => a.name).toList(),
      'dwellTimeSeconds': dwellTimeSeconds,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggered': lastTriggered?.toIso8601String(),
    };
  }

  factory Geofence.fromMap(Map<String, dynamic> map) {
    return Geofence(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: GeofenceType.values.firstWhere((e) => e.name == map['type']),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      radiusMeters: map['radiusMeters']?.toDouble(),
      polygon: (map['polygon'] as List?)
          ?.map((p) => (lat: (p['lat'] as num).toDouble(), lng: (p['lng'] as num).toDouble()))
          .toList(),
      actions: (map['actions'] as List)
          .map((a) => GeofenceAction.values.firstWhere((e) => e.name == a))
          .toList(),
      dwellTimeSeconds: (map['dwellTimeSeconds'] as num?)?.toDouble() ?? 10,
      enabled: map['enabled'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      lastTriggered: map['lastTriggered'] != null ? DateTime.parse(map['lastTriggered']) : null,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory Geofence.fromJson(String json) => Geofence.fromMap(jsonDecode(json));
}

/// A geofence event log entry
class GeofenceEvent {
  final String geofenceId;
  final String geofenceName;
  final GeofenceTransition transition;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  GeofenceEvent({
    required this.geofenceId,
    required this.geofenceName,
    required this.transition,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'geofenceId': geofenceId,
    'geofenceName': geofenceName,
    'transition': transition.name,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
  };
}
