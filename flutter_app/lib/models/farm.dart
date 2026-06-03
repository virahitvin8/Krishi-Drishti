/// Saved farm field data model
class Farm {
  final String id;
  String name;
  final double latitude;
  final double longitude;
  final int healthScore;
  final String cropType;
  final String savedAt;

  Farm({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.healthScore = 0,
    this.cropType = 'general',
    required this.savedAt,
  });

  factory Farm.fromJson(Map<String, dynamic> json) => Farm(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    latitude: (json['latitude'] ?? 0).toDouble(),
    longitude: (json['longitude'] ?? 0).toDouble(),
    healthScore: json['health_score'] ?? json['healthScore'] ?? 0,
    cropType: json['crop_type'] ?? json['cropType'] ?? 'general',
    savedAt: json['saved_at'] ?? json['savedAt'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'health_score': healthScore,
    'crop_type': cropType,
    'saved_at': savedAt,
  };
}
