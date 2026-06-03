/// Analysis data model - complete crop health analysis result
class Analysis {
  final String fieldId;
  final double latitude;
  final double longitude;
  final double areaHectares;
  final String analysisDate;

  // Vegetation indices
  final double ndvi;
  final double evi;
  final double ndwi;
  final double gndvi;
  final double reip;
  final double savi;

  // Health
  final int healthScore;
  final String healthStatus;
  final String healthColor;

  // Soil
  final double soilMoisturePct;
  final int drainageScore;
  final double? sarSoilMoisture;

  // Weather
  final double temperatureC;
  final double humidityPct;
  final double precipitationMm;
  final double windSpeedKmh;
  final double solarRadiationMj;
  final double evapotranspirationMm;
  final double forecastRain48h;

  // Pest
  final int pestRiskScore;
  final String pestRiskLevel;

  // Other
  final List<String> recommendations;
  final List<GridCell> hotspotGrid;
  final List<SatelliteSource> satelliteSources;

  Analysis({
    required this.fieldId,
    required this.latitude,
    required this.longitude,
    this.areaHectares = 1.0,
    required this.analysisDate,
    this.ndvi = 0,
    this.evi = 0,
    this.ndwi = 0,
    this.gndvi = 0,
    this.reip = 0,
    this.savi = 0,
    this.healthScore = 0,
    this.healthStatus = 'Unknown',
    this.healthColor = '#2ECC71',
    this.soilMoisturePct = 0,
    this.drainageScore = 50,
    this.sarSoilMoisture,
    this.temperatureC = 0,
    this.humidityPct = 0,
    this.precipitationMm = 0,
    this.windSpeedKmh = 0,
    this.solarRadiationMj = 0,
    this.evapotranspirationMm = 0,
    this.forecastRain48h = 0,
    this.pestRiskScore = 0,
    this.pestRiskLevel = 'Low',
    this.recommendations = const [],
    this.hotspotGrid = const [],
    this.satelliteSources = const [],
  });

  factory Analysis.fromJson(Map<String, dynamic> json) {
    final veg = json['vegetation'] ?? {};
    final health = json['health_score'] ?? {};
    final soil = json['soil'] ?? {};
    final weather = json['weather'] ?? {};
    final pest = json['pest_risk'] ?? {};

    return Analysis(
      fieldId: json['field_id'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      areaHectares: (json['area_hectares'] ?? 1.0).toDouble(),
      analysisDate: json['analysis_date'] ?? '',
      ndvi: ((veg['ndvi'] ?? 0) as num).toDouble(),
      evi: ((veg['evi'] ?? 0) as num).toDouble(),
      ndwi: ((veg['ndwi'] ?? 0) as num).toDouble(),
      gndvi: ((veg['gndvi'] ?? 0) as num).toDouble(),
      reip: ((veg['reip'] ?? 0) as num).toDouble(),
      savi: ((veg['savi'] ?? 0) as num).toDouble(),
      healthScore: (health['overall'] ?? 0).toInt(),
      healthStatus: health['status'] ?? 'Unknown',
      healthColor: health['color'] ?? '#2ECC71',
      soilMoisturePct: ((soil['moisture_pct'] ?? 0) as num).toDouble(),
      drainageScore: (soil['drainage_score'] ?? 50).toInt(),
      sarSoilMoisture: (soil['sar_soil_moisture'] as num?)?.toDouble(),
      temperatureC: ((weather['temperature_c'] ?? 0) as num).toDouble(),
      humidityPct: ((weather['humidity_pct'] ?? 0) as num).toDouble(),
      precipitationMm: ((weather['precipitation_mm'] ?? 0) as num).toDouble(),
      windSpeedKmh: ((weather['wind_speed_kmh'] ?? 0) as num).toDouble(),
      solarRadiationMj: ((weather['solar_radiation_mj'] ?? 0) as num).toDouble(),
      evapotranspirationMm: ((weather['evapotranspiration_mm'] ?? 0) as num).toDouble(),
      forecastRain48h: ((weather['forecast_rain_48h'] ?? 0) as num).toDouble(),
      pestRiskScore: (pest['score'] ?? 0).toInt(),
      pestRiskLevel: pest['level'] ?? 'Low',
      recommendations: List<String>.from(json['recommendations'] ?? []),
      hotspotGrid: (json['hotspot_grid'] as List? ?? [])
          .map((e) => GridCell.fromJson(e))
          .toList(),
      satelliteSources: (json['satellite_sources'] as List? ?? [])
          .map((e) => SatelliteSource.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'field_id': fieldId,
    'latitude': latitude,
    'longitude': longitude,
    'area_hectares': areaHectares,
    'analysis_date': analysisDate,
    'ndvi': ndvi,
    'evi': evi,
    'ndwi': ndwi,
    'gndvi': gndvi,
    'reip': reip,
    'savi': savi,
    'health_score': healthScore,
    'health_status': healthStatus,
    'soil_moisture_pct': soilMoisturePct,
    'drainage_score': drainageScore,
    'temperature_c': temperatureC,
    'humidity_pct': humidityPct,
    'precipitation_mm': precipitationMm,
    'pest_risk_score': pestRiskScore,
  };
}

class GridCell {
  final double lat;
  final double lng;
  final double ndvi;
  final String status;
  final String color;

  GridCell({
    required this.lat,
    required this.lng,
    required this.ndvi,
    required this.status,
    required this.color,
  });

  factory GridCell.fromJson(Map<String, dynamic> json) => GridCell(
    lat: (json['lat'] ?? 0).toDouble(),
    lng: (json['lng'] ?? 0).toDouble(),
    ndvi: (json['ndvi'] ?? 0).toDouble(),
    status: json['status'] ?? 'healthy',
    color: json['color'] ?? '#64B5F6',
  );

  bool get isStressed => status == 'stressed';
}

class SatelliteSource {
  final String name;
  final String mission;
  final int resolutionM;
  final List<String> bandsUsed;
  final String acquisitionDate;

  SatelliteSource({
    required this.name,
    required this.mission,
    required this.resolutionM,
    required this.bandsUsed,
    required this.acquisitionDate,
  });

  factory SatelliteSource.fromJson(Map<String, dynamic> json) => SatelliteSource(
    name: json['name'] ?? '',
    mission: json['mission'] ?? '',
    resolutionM: json['resolution_m'] ?? 0,
    bandsUsed: List<String>.from(json['bands_used'] ?? []),
    acquisitionDate: json['acquisition_date'] ?? '',
  );
}
