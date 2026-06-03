import 'dart:convert';

/// Types of field surveys
enum SurveyType {
  pestCheck,
  soilSample,
  irrigationStatus,
  cropCondition,
  generalObservation,
  damageAssessment,
  nutrientDeficiency,
}

/// Form field template for structured surveys
class SurveyFormField {
  final String label;
  final String key;
  final SurveyFieldType fieldType;
  final List<String>? options;
  final bool required;

  SurveyFormField({
    required this.label,
    required this.key,
    this.fieldType = SurveyFieldType.text,
    this.options,
    this.required = false,
  });

  Map<String, dynamic> toMap() => {
    'label': label,
    'key': key,
    'fieldType': fieldType.name,
    'options': options,
    'required': required,
  };

  factory SurveyFormField.fromMap(Map<String, dynamic> map) => SurveyFormField(
    label: map['label'],
    key: map['key'],
    fieldType: SurveyFieldType.values.firstWhere((e) => e.name == map['fieldType']),
    options: (map['options'] as List?)?.cast<String>(),
    required: map['required'] ?? false,
  );
}

enum SurveyFieldType {
  text,
  number,
  dropdown,
  rating,     // 1-5
  yesNo,
  photo,
  voiceNote,
  multilineText,
}

/// A single data point collected during field survey
class SurveyPoint {
  final String id;
  final String? trackId;
  final SurveyType type;
  final double latitude;
  final double longitude;
  final double? altitude;
  final DateTime timestamp;
  final String? name;
  final String? description;
  final List<String> photoPaths;
  final String? voiceNotePath;
  final Map<String, dynamic> formData; // Structured form responses
  final String? cropType;
  final String? growthStage;
  final int? healthRating; // 1-5
  final bool synced;

  SurveyPoint({
    required this.id,
    this.trackId,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.altitude,
    DateTime? timestamp,
    this.name,
    this.description,
    this.photoPaths = const [],
    this.voiceNotePath,
    this.formData = const {},
    this.cropType,
    this.growthStage,
    this.healthRating,
    this.synced = false,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Get a human-readable survey type name
  String get typeName {
    switch (type) {
      case SurveyType.pestCheck: return 'Pest Check';
      case SurveyType.soilSample: return 'Soil Sample';
      case SurveyType.irrigationStatus: return 'Irrigation Status';
      case SurveyType.cropCondition: return 'Crop Condition';
      case SurveyType.generalObservation: return 'Observation';
      case SurveyType.damageAssessment: return 'Damage Assessment';
      case SurveyType.nutrientDeficiency: return 'Nutrient Deficiency';
    }
  }

  /// Get icon for survey type
  String get typeIcon {
    switch (type) {
      case SurveyType.pestCheck: return '🐛';
      case SurveyType.soilSample: return '🧪';
      case SurveyType.irrigationStatus: return '💧';
      case SurveyType.cropCondition: return '🌾';
      case SurveyType.generalObservation: return '👁️';
      case SurveyType.damageAssessment: return '⚠️';
      case SurveyType.nutrientDeficiency: return '🧬';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'trackId': trackId,
    'type': type.name,
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'timestamp': timestamp.toIso8601String(),
    'name': name,
    'description': description,
    'photoPaths': photoPaths,
    'voiceNotePath': voiceNotePath,
    'formData': formData,
    'cropType': cropType,
    'growthStage': growthStage,
    'healthRating': healthRating,
    'synced': synced,
  };

  factory SurveyPoint.fromMap(Map<String, dynamic> map) => SurveyPoint(
    id: map['id'],
    trackId: map['trackId'],
    type: SurveyType.values.firstWhere((e) => e.name == map['type']),
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    altitude: map['altitude']?.toDouble(),
    timestamp: DateTime.parse(map['timestamp']),
    name: map['name'],
    description: map['description'],
    photoPaths: (map['photoPaths'] as List?)?.cast<String>() ?? [],
    voiceNotePath: map['voiceNotePath'],
    formData: Map<String, dynamic>.from(map['formData'] ?? {}),
    cropType: map['cropType'],
    growthStage: map['growthStage'],
    healthRating: map['healthRating'],
    synced: map['synced'] ?? false,
  );

  String toJson() => jsonEncode(toMap());
  factory SurveyPoint.fromJson(String json) => SurveyPoint.fromMap(jsonDecode(json));
}

/// Extension to get icon for SurveyType
String surveyTypeIcon(SurveyType type) {
  switch (type) {
    case SurveyType.pestCheck: return '🐛';
    case SurveyType.soilSample: return '🧪';
    case SurveyType.irrigationStatus: return '💧';
    case SurveyType.cropCondition: return '🌾';
    case SurveyType.generalObservation: return '👁️';
    case SurveyType.damageAssessment: return '⚠️';
    case SurveyType.nutrientDeficiency: return '🧬';
  }
}

/// Pre-defined survey form templates
class SurveyTemplate {
  final SurveyType type;
  final String name;
  final List<SurveyFormField> fields;

  SurveyTemplate({required this.type, required this.name, required this.fields});

  static final Map<SurveyType, SurveyTemplate> templates = {
    SurveyType.pestCheck: SurveyTemplate(
      type: SurveyType.pestCheck,
      name: 'Pest Check',
      fields: [
        SurveyFormField(label: 'Pest Type', key: 'pest_type', fieldType: SurveyFieldType.dropdown,
            options: ['Aphids', 'Whitefly', 'Thrips', 'Bollworm', 'Leaf Miner', 'Other']),
        SurveyFormField(label: 'Severity', key: 'severity', fieldType: SurveyFieldType.rating),
        SurveyFormField(label: 'Affected Area %', key: 'affected_area', fieldType: SurveyFieldType.number),
        SurveyFormField(label: 'Crop Stage', key: 'crop_stage', fieldType: SurveyFieldType.dropdown,
            options: ['Vegetative', 'Flowering', 'Fruiting', 'Maturity']),
        SurveyFormField(label: 'Notes', key: 'notes', fieldType: SurveyFieldType.multilineText),
        SurveyFormField(label: 'Photo', key: 'photo', fieldType: SurveyFieldType.photo),
      ],
    ),
    SurveyType.soilSample: SurveyTemplate(
      type: SurveyType.soilSample,
      name: 'Soil Sample',
      fields: [
        SurveyFormField(label: 'Sample Depth (cm)', key: 'depth_cm', fieldType: SurveyFieldType.number),
        SurveyFormField(label: 'Soil Type', key: 'soil_type', fieldType: SurveyFieldType.dropdown,
            options: ['Clay', 'Loam', 'Sandy', 'Silt', 'Laterite', 'Alluvial']),
        SurveyFormField(label: 'Moisture Level', key: 'moisture', fieldType: SurveyFieldType.dropdown,
            options: ['Dry', 'Moist', 'Wet', 'Saturated']),
        SurveyFormField(label: 'Color', key: 'color', fieldType: SurveyFieldType.dropdown,
            options: ['Brown', 'Red', 'Black', 'Yellow', 'Grey']),
        SurveyFormField(label: 'Notes', key: 'notes', fieldType: SurveyFieldType.multilineText),
      ],
    ),
    SurveyType.irrigationStatus: SurveyTemplate(
      type: SurveyType.irrigationStatus,
      name: 'Irrigation Status',
      fields: [
        SurveyFormField(label: 'Irrigation Type', key: 'irrigation_type', fieldType: SurveyFieldType.dropdown,
            options: ['Drip', 'Sprinkler', 'Flood', 'Furrow', 'Rainfed']),
        SurveyFormField(label: 'Status', key: 'status', fieldType: SurveyFieldType.dropdown,
            options: ['Active', 'Needs Repair', 'Not Installed', 'Scheduled']),
        SurveyFormField(label: 'Water Availability', key: 'water_avail', fieldType: SurveyFieldType.dropdown,
            options: ['Adequate', 'Limited', 'Scarce']),
        SurveyFormField(label: 'Notes', key: 'notes', fieldType: SurveyFieldType.multilineText),
      ],
    ),
    SurveyType.nutrientDeficiency: SurveyTemplate(
      type: SurveyType.nutrientDeficiency,
      name: 'Nutrient Deficiency',
      fields: [
        SurveyFormField(label: 'Symptom Type', key: 'symptom', fieldType: SurveyFieldType.dropdown,
            options: ['Yellowing', 'Browning', 'Stunted Growth', 'Leaf Curl', 'Chlorosis', 'Necrosis']),
        SurveyFormField(label: 'Affected Leaves', key: 'affected_leaves', fieldType: SurveyFieldType.dropdown,
            options: ['Lower', 'Upper', 'All', 'Scattered']),
        SurveyFormField(label: 'Suspected Deficiency', key: 'deficiency', fieldType: SurveyFieldType.dropdown,
            options: ['Nitrogen', 'Phosphorus', 'Potassium', 'Zinc', 'Iron', 'Magnesium', 'Unknown']),
        SurveyFormField(label: 'Severity', key: 'severity', fieldType: SurveyFieldType.rating),
        SurveyFormField(label: 'Photo', key: 'photo', fieldType: SurveyFieldType.photo),
      ],
    ),
    SurveyType.cropCondition: SurveyTemplate(
      type: SurveyType.cropCondition,
      name: 'Crop Condition',
      fields: [
        SurveyFormField(label: 'Overall Health', key: 'health', fieldType: SurveyFieldType.rating),
        SurveyFormField(label: 'Growth Stage', key: 'growth_stage', fieldType: SurveyFieldType.dropdown,
            options: ['Germination', 'Vegetative', 'Flowering', 'Fruiting', 'Harvest']),
        SurveyFormField(label: 'Crop Density', key: 'density', fieldType: SurveyFieldType.dropdown,
            options: ['Excellent', 'Good', 'Fair', 'Poor']),
        SurveyFormField(label: 'Weed Pressure', key: 'weed_pressure', fieldType: SurveyFieldType.dropdown,
            options: ['None', 'Low', 'Medium', 'High']),
        SurveyFormField(label: 'Notes', key: 'notes', fieldType: SurveyFieldType.multilineText),
      ],
    ),
  };
}
