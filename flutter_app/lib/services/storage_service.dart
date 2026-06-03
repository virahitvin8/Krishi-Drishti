import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/farm.dart';

/// Local storage for user data, saved farms, and preferences
class StorageService {
  static const _keyUser = 'krishi_user';
  static const _keyFarms = 'krishi_saved_farms';
  static const _keyPrefs = 'krishi_prefs';
  static const _keyLastUpdate = 'krishi_last_update';

  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> init() async {
    if (_instance != null) return _instance!;
    _instance = StorageService._();
    _instance!._prefs = await SharedPreferences.getInstance();
    return _instance!;
  }

  static StorageService get instance {
    if (_instance == null) {
      throw StateError('StorageService not initialized. Call StorageService.init() first.');
    }
    return _instance!;
  }

  // ============= User =============
  AppUser? getUser() {
    final data = _prefs.getString(_keyUser);
    if (data == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(data));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(AppUser user) async {
    await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<void> clearUser() async {
    await _prefs.remove(_keyUser);
  }

  // ============= Saved Farms =============
  List<Farm> getSavedFarms() {
    final data = _prefs.getString(_keyFarms);
    if (data == null) return [];
    try {
      final list = jsonDecode(data) as List;
      return list.map((e) => Farm.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFarms(List<Farm> farms) async {
    final data = jsonEncode(farms.map((f) => f.toJson()).toList());
    await _prefs.setString(_keyFarms, data);
  }

  Future<void> addFarm(Farm farm) async {
    final farms = getSavedFarms();
    farms.add(farm);
    await saveFarms(farms);
  }

  Future<void> removeFarm(String farmId) async {
    final farms = getSavedFarms()..removeWhere((f) => f.id == farmId);
    await saveFarms(farms);
  }

  // ============= Preferences =============
  Map<String, dynamic> getPreferences() {
    final data = _prefs.getString(_keyPrefs);
    if (data == null) return {'autoRefresh': true, 'notifications': true};
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return {'autoRefresh': true, 'notifications': true};
    }
  }

  Future<void> savePreferences(Map<String, dynamic> prefs) async {
    await _prefs.setString(_keyPrefs, jsonEncode(prefs));
  }

  // ============= Last Update =============
  String? getLastUpdate() => _prefs.getString(_keyLastUpdate);

  Future<void> setLastUpdate(String timestamp) async {
    await _prefs.setString(_keyLastUpdate, timestamp);
  }
}
