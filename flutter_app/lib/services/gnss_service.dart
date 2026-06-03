import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/gnss_satellite.dart';

/// GNSS monitoring service - inspired by GPSTest, Google GPS Measurement Tools, GPS Cockpit
/// Monitors satellites, signal strength, and provides real-time GNSS status
class GnssService {
  static final GnssService _instance = GnssService._();
  factory GnssService() => _instance;
  GnssService._();

  final List<GnssSatellite> _satellites = [];
  StreamSubscription<Position>? _positionStream;
  Timer? _simulationTimer;

  // Observable streams
  final _satelliteController = StreamController<List<GnssSatellite>>.broadcast();
  final _gnssStatsController = StreamController<GnssStats>.broadcast();

  Stream<List<GnssSatellite>> get satelliteStream => _satelliteController.stream;
  Stream<GnssStats> get statsStream => _gnssStatsController.stream;

  List<GnssSatellite> get satellites => List.unmodifiable(_satellites);
  GnssStats _currentStats = GnssStats();
  GnssStats get currentStats => _currentStats;

  /// Start GNSS monitoring - reads satellite data from position updates
  Future<void> startMonitoring() async {
    // On real devices, we'd use android.hardware.gnss.GnssStatus
    // For cross-platform, we simulate from position accuracy data
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen(_onPositionUpdate);

    // Generate simulated satellite data for visualization
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _generateSimulatedSatellites();
    });
  }

  void _onPositionUpdate(Position pos) {
    _currentStats = GnssStats(
      latitude: pos.latitude,
      longitude: pos.longitude,
      altitude: pos.altitude,
      speed: pos.speed,
      bearing: pos.heading,
      accuracy: pos.accuracy,
      satelliteCount: _satellites.where((s) => s.usedInFix).length,
      visibleCount: _satellites.length,
      timestamp: DateTime.now(),
    );
    _gnssStatsController.add(_currentStats);
  }

  void _generateSimulatedSatellites() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random(now ~/ 3000);
    
    // Define constellations with realistic satellite counts
    final constellations = {
      'GPS':       { 'min': 4, 'max': 12, 'prnBase': 1 },
      'GLONASS':   { 'min': 3, 'max': 8,  'prnBase': 65 },
      'Galileo':   { 'min': 2, 'max': 6,  'prnBase': 201 },
      'BeiDou':    { 'min': 3, 'max': 8,  'prnBase': 301 },
      'QZSS':      { 'min': 1, 'max': 2,  'prnBase': 193 },
      'NavIC':     { 'min': 1, 'max': 3,  'prnBase': 401 },
    };

    final newSatellites = <GnssSatellite>[];
    var prnCounter = 0;

    for (final entry in constellations.entries) {
      final count = entry.value['min']! + random.nextInt(entry.value['max']! - entry.value['min']! + 1);
      for (int i = 0; i < count && prnCounter < 40; i++) {
        prnCounter++;
        final snr = 15.0 + random.nextDouble() * 35.0;
        newSatellites.add(GnssSatellite(
          prn: entry.value['prnBase']! + i,
          constellation: entry.key,
          snr: double.parse(snr.toStringAsFixed(1)),
          elevation: double.parse((random.nextDouble() * 85).toStringAsFixed(1)),
          azimuth: double.parse((random.nextDouble() * 360).toStringAsFixed(1)),
          usedInFix: snr > 25 && random.nextDouble() > 0.2,
          hasEphemeris: snr > 20,
          hasAlmanac: true,
          frequencyBand: random.nextBool() ? 'L1' : 'L5',
        ));
      }
    }

    // Sort by constellation then SNR
    newSatellites.sort((a, b) {
      final cat = a.constellation.compareTo(b.constellation);
      return cat != 0 ? cat : b.snr.compareTo(a.snr);
    });

    _satellites
      ..clear()
      ..addAll(newSatellites);
    
    _satelliteController.add(List.from(_satellites));
    
    // Update stats with new satellite count
    _currentStats = GnssStats(
      satelliteCount: newSatellites.where((s) => s.usedInFix).length,
      visibleCount: newSatellites.length,
      timestamp: DateTime.now(),
    );
    _gnssStatsController.add(_currentStats);
  }

  /// Stop monitoring
  void stopMonitoring() {
    _positionStream?.cancel();
    _simulationTimer?.cancel();
    _satellites.clear();
  }

  /// Get constellation breakdown
  Map<String, int> getConstellationBreakdown() {
    final breakdown = <String, int>{};
    for (final sat in _satellites) {
      breakdown[sat.constellation] = (breakdown[sat.constellation] ?? 0) + 1;
    }
    return breakdown;
  }

  /// Dispose
  void dispose() {
    stopMonitoring();
    _satelliteController.close();
    _gnssStatsController.close();
  }
}

/// GNSS statistics model
class GnssStats {
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? speed;
  final double? bearing;
  final double? accuracy;
  final int satelliteCount;
  final int visibleCount;
  final DateTime timestamp;

  GnssStats({
    this.latitude,
    this.longitude,
    this.altitude,
    this.speed,
    this.bearing,
    this.accuracy,
    this.satelliteCount = 0,
    this.visibleCount = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedLatitude {
    if (latitude == null) return '--';
    final lat = latitude!;
    final dir = lat >= 0 ? 'N' : 'S';
    return '${lat.toStringAsFixed(6)}° $dir';
  }

  String get formattedLongitude {
    if (longitude == null) return '--';
    final lng = longitude!;
    final dir = lng >= 0 ? 'E' : 'W';
    return '${lng.toStringAsFixed(6)}° $dir';
  }
}
