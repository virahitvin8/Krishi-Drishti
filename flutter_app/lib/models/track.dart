import 'dart:convert';

/// GPS track point
class TrackPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speed;
  final double? bearing;
  final double? accuracy;
  final DateTime timestamp;

  TrackPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.bearing,
    this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lon': longitude,
    'alt': altitude,
    'speed': speed,
    'bearing': bearing,
    'accuracy': accuracy,
    'time': timestamp.toIso8601String(),
  };

  String toGpxPoint({bool isTrackPoint = true}) {
    final tag = isTrackPoint ? 'trkpt' : 'wpt';
    final ele = altitude != null ? '\n      <ele>$altitude</ele>' : '';
    final time = '\n      <time>${timestamp.toUtc().toIso8601String()}</time>';
    return '  <$tag lat="$latitude" lon="$longitude">$ele$time\n  </$tag>';
  }
}

/// A GPS waypoint (POI) with optional media
class Waypoint {
  final String id;
  final double latitude;
  final double longitude;
  final double? altitude;
  final String? name;
  final String? description;
  final String? category;
  final List<String> photoPaths;
  final String? voiceNotePath;
  final DateTime timestamp;

  Waypoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.name,
    this.description,
    this.category,
    this.photoPaths = const [],
    this.voiceNotePath,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'lat': latitude,
    'lon': longitude,
    'alt': altitude,
    'name': name,
    'description': description,
    'category': category,
    'photos': photoPaths,
    'voice_note': voiceNotePath,
    'time': timestamp.toIso8601String(),
  };

  String toGpx() {
    final nameTag = name != null ? '\n    <name>$name</name>' : '';
    final descTag = description != null ? '\n    <desc>$description</desc>' : '';
    final ele = altitude != null ? '\n    <ele>$altitude</ele>' : '';
    final catTag = category != null ? '\n    <type>$category</type>' : '';
    final time = '\n    <time>${timestamp.toUtc().toIso8601String()}</time>';
    return '  <wpt lat="$latitude" lon="$longitude">$nameTag$descTag$ele$catTag$time\n  </wpt>';
  }
}

/// Complete GPS track with metadata
class GpsTrack {
  final String id;
  String name;
  final DateTime startTime;
  DateTime? endTime;
  final List<TrackPoint> points;
  final List<Waypoint> waypoints;
  TrackStatus status;
  double totalDistanceKm;
  double averageSpeedKmh;

  GpsTrack({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.points = const [],
    this.waypoints = const [],
    this.status = TrackStatus.recording,
    this.totalDistanceKm = 0,
    this.averageSpeedKmh = 0,
  });

  /// Duration of the track
  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  /// Number of unique satellites (if available)
  int get pointCount => points.length;

  /// Export track to GPX format
  String toGpx() {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln('<gpx version="1.1" creator="KrishiDrishti"');
    buf.writeln('  xmlns="http://www.topografix.com/GPX/1/1"');
    buf.writeln('  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');
    buf.writeln('  <metadata>');
    buf.writeln('    <name>${name.replaceAll('&', '&amp;')}</name>');
    buf.writeln('    <time>${startTime.toUtc().toIso8601String()}</time>');
    buf.writeln('  </metadata>');
    
    // Waypoints
    for (final wpt in waypoints) {
      buf.writeln(wpt.toGpx());
    }
    
    // Track
    buf.writeln('  <trk>');
    buf.writeln('    <name>${name.replaceAll('&', '&amp;')}</name>');
    buf.writeln('    <trkseg>');
    for (final pt in points) {
      buf.writeln(pt.toGpxPoint());
    }
    buf.writeln('    </trkseg>');
    buf.writeln('  </trk>');
    buf.writeln('</gpx>');
    
    return buf.toString();
  }

  /// Export to JSON
  String toJson() {
    return jsonEncode({
      'id': id,
      'name': name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status.name,
      'distance_km': totalDistanceKm,
      'avg_speed': averageSpeedKmh,
      'points': points.map((p) => p.toJson()).toList(),
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
    });
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'total_points': points.length,
    'waypoint_count': waypoints.length,
    'distance_km': totalDistanceKm.toStringAsFixed(2),
    'duration_min': (duration.inMinutes).toString(),
    'date': startTime.toIso8601String(),
  };
}

enum TrackStatus { recording, paused, completed, saved }
