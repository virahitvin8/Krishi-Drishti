import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../models/analysis.dart';
import '../models/user.dart';

/// HTTP API service for communicating with the Krishi Drishti backend
class ApiService {
  static const String _baseUrl = 'https://krishi-drishti-backend.onrender.com';
  static const Duration _timeout = Duration(seconds: 30);

  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final http.Client _client = http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// ==================== ANALYSIS ====================

  /// Analyze a field by coordinates
  Future<Analysis> analyzeField({
    required double latitude,
    required double longitude,
    String cropType = 'general',
    String language = 'en',
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/v1/analyze'),
        headers: _headers,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'crop_type': cropType,
          'language': language,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Analysis.fromJson(data['analysis'] ?? {});
      } else {
        debugPrint('Analysis API error: ${response.statusCode}');
        return generateMockAnalysis(latitude, longitude);
      }
    } catch (e) {
      debugPrint('Analysis API exception: $e');
      return generateMockAnalysis(latitude, longitude);
    }
  }

  /// ==================== CSV UPLOAD ====================

  /// Upload a CSV file for batch analysis
  Future<Map<String, dynamic>> uploadCsv(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/v1/upload-csv'),
      );
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('text', 'csv'),
      ));

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'detail': 'Upload failed: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'detail': 'Connection error: $e'};
    }
  }

  /// ==================== USER ====================

  /// Register a new user
  Future<bool> registerUser(AppUser user) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/v1/user/register'),
        headers: _headers,
        body: jsonEncode({
          'username': user.username,
          'display_name': user.displayName,
          'phone': user.phone,
          'language': user.language,
        }),
      ).timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  /// Get user profile
  Future<AppUser?> getUser(String username) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/v1/user/$username'),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          return AppUser.fromJson(data['user']);
        }
      }
    } catch (e) {
      debugPrint('Get user error: $e');
    }
    return null;
  }

  /// ==================== DASHBOARD ====================

  /// Get dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/v1/dashboard'),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
    }
    return {};
  }

  /// ==================== HEALTH CHECK ====================

  /// Check if backend is reachable
  Future<bool> isBackendReachable() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// ==================== MOCK DATA (fallback) ====================

  /// Generate mock analysis data when backend is unreachable
  Analysis generateMockAnalysis(double lat, double lng) {
    final seed = (lat * 100 + lng * 100).abs().toInt();
    final score = 65 + (seed % 30);
    return Analysis(
      fieldId: 'field_${DateTime.now().millisecondsSinceEpoch}',
      latitude: lat,
      longitude: lng,
      analysisDate: DateTime.now().toIso8601String(),
      ndvi: 0.35 + (seed % 35) / 100,
      evi: 0.30 + (seed % 40) / 100,
      ndwi: 0.15 + (seed % 35) / 100,
      gndvi: 0.32 + (seed % 38) / 100,
      reip: 0.25 + (seed % 25) / 100,
      savi: 0.28 + (seed % 30) / 100,
      healthScore: score,
      healthStatus: score >= 80 ? 'Healthy' : score >= 65 ? 'Good' : 'Moderate',
      healthColor: score >= 80 ? '#2ECC71' : score >= 65 ? '#F1C40F' : '#E67E22',
      soilMoisturePct: 15.0 + (seed % 20),
      drainageScore: 40 + (seed % 35),
      temperatureC: 28.0 + (seed % 10).toDouble(),
      humidityPct: 50.0 + (seed % 30).toDouble(),
      precipitationMm: (seed % 15).toDouble(),
      windSpeedKmh: 8.0 + (seed % 15).toDouble(),
      solarRadiationMj: 18.0 + (seed % 10).toDouble(),
      evapotranspirationMm: 3.5 + (seed % 3).toDouble(),
      forecastRain48h: (seed % 20).toDouble(),
      pestRiskScore: 10 + (seed % 40),
      pestRiskLevel: 'Low',
      recommendations: [
        '✅ Your crop is in good health. Continue regular monitoring.',
        '💧 Maintain irrigation schedule.',
        '📊 Next satellite pass: Sentinel-2 in ~3 days.',
      ],
    );
  }

  void dispose() {
    _client.close();
  }
}
