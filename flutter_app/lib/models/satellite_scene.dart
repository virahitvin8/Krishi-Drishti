import 'dart:convert';

/// Satellite data source
enum SatelliteSource {
  sentinel2,
  landsat8,
  landsat9,
  modis,
}

/// Scene availability and metadata
class SatelliteScene {
  final String id;
  final SatelliteSource source;
  final DateTime acquisitionDate;
  final double latitude;
  final double longitude;
  final double cloudCover;
  final double? ndviMin;
  final double? ndviMax;
  final double? ndviMean;
  final String? thumbnailUrl;
  final String? tileUrl;  // WMTS tile URL for overlay
  final bool available;
  final Map<String, dynamic>? metadata;

  SatelliteScene({
    required this.id,
    required this.source,
    required this.acquisitionDate,
    required this.latitude,
    required this.longitude,
    this.cloudCover = 0,
    this.ndviMin,
    this.ndviMax,
    this.ndviMean,
    this.thumbnailUrl,
    this.tileUrl,
    this.available = true,
    this.metadata,
  });

  /// Human-readable source name
  String get sourceName {
    switch (source) {
      case SatelliteSource.sentinel2: return 'Sentinel-2';
      case SatelliteSource.landsat8: return 'Landsat 8';
      case SatelliteSource.landsat9: return 'Landsat 9';
      case SatelliteSource.modis: return 'MODIS';
    }
  }

  /// Color band for display
  String get sourceColor {
    switch (source) {
      case SatelliteSource.sentinel2: return '#2E7D32';
      case SatelliteSource.landsat8: return '#1565C0';
      case SatelliteSource.landsat9: return '#0D47A1';
      case SatelliteSource.modis: return '#E65100';
    }
  }

  /// NDVI health classification
  String? get ndviStatus {
    if (ndviMean == null) return null;
    if (ndviMean! < 0.2) return 'Barren';
    if (ndviMean! < 0.4) return 'Sparse';
    if (ndviMean! < 0.6) return 'Moderate';
    if (ndviMean! < 0.8) return 'Dense';
    return 'Very Dense';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'source': source.name,
    'acquisitionDate': acquisitionDate.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'cloudCover': cloudCover,
    'ndviMin': ndviMin,
    'ndviMax': ndviMax,
    'ndviMean': ndviMean,
    'thumbnailUrl': thumbnailUrl,
    'tileUrl': tileUrl,
    'available': available,
    'metadata': metadata,
  };

  factory SatelliteScene.fromMap(Map<String, dynamic> map) => SatelliteScene(
    id: map['id'],
    source: SatelliteSource.values.firstWhere((e) => e.name == map['source']),
    acquisitionDate: DateTime.parse(map['acquisitionDate']),
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    cloudCover: (map['cloudCover'] as num).toDouble(),
    ndviMin: map['ndviMin']?.toDouble(),
    ndviMax: map['ndviMax']?.toDouble(),
    ndviMean: map['ndviMean']?.toDouble(),
    thumbnailUrl: map['thumbnailUrl'],
    tileUrl: map['tileUrl'],
    available: map['available'] ?? true,
    metadata: map['metadata'] as Map<String, dynamic>?,
  );

  String toJson() => jsonEncode(toMap());
  factory SatelliteScene.fromJson(String json) => SatelliteScene.fromMap(jsonDecode(json));
}

/// NDVI color ramp data for map overlay
class NdviColorRamp {
  static const List<({double threshold, int red, int green, int blue})> ramp = [
    (threshold: 0.0, red: 165, green: 0, blue: 38),     // Dark red - water/barren
    (threshold: 0.1, red: 215, green: 48, blue: 39),      // Red
    (threshold: 0.2, red: 244, green: 109, blue: 67),     // Orange
    (threshold: 0.3, red: 255, green: 188, blue: 74),     // Yellow
    (threshold: 0.4, red: 208, green: 216, blue: 82),     // Yellow-green
    (threshold: 0.5, red: 143, green: 200, blue: 80),     // Light green
    (threshold: 0.6, red: 77, green: 175, blue: 74),      // Green
    (threshold: 0.7, red: 33, green: 150, blue: 56),      // Medium green
    (threshold: 0.8, red: 0, green: 120, blue: 40),       // Dark green
    (threshold: 0.9, red: 0, green: 90, blue: 30),        // Very dark green
    (threshold: 1.0, red: 0, green: 60, blue: 20),        // Deep green
  ];

  /// Get color for NDVI value
  static ({int r, int g, int b}) colorForNdvi(double ndvi) {
    for (int i = ramp.length - 1; i >= 0; i--) {
      if (ndvi >= ramp[i].threshold) {
        return (r: ramp[i].red, g: ramp[i].green, b: ramp[i].blue);
      }
    }
    return (r: ramp[0].red, g: ramp[0].green, b: ramp[0].blue);
  }
}
