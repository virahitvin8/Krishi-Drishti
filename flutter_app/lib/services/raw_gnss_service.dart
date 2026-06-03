import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/gnss_satellite.dart';

/// Raw GNSS data service - connects to REAL Android GnssStatus.Callback via EventChannel
/// Falls back to realistic simulation when native channel is unavailable
/// (e.g., on iOS, emulators without GPS, or when permissions are denied)
class RawGnssService {
  static final RawGnssService _instance = RawGnssService._();
  factory RawGnssService() => _instance;
  RawGnssService._();

  // Native EventChannels for real Android GNSS data
  static const _satelliteChannel = EventChannel('com.krishidrishti/gnss_satellites');
  static const _nmeaChannel = EventChannel('com.krishidrishti/gnss_nmea');
  static const _constellationChannel = EventChannel('com.krishidrishti/gnss_constellations');

  // Fallback simulation timers
  StreamSubscription<Position>? _positionStream;
  Timer? _simulationTimer;
  Timer? _nmeaTimer;

  // Real data subscriptions
  StreamSubscription? _nativeSatSub;
  StreamSubscription? _nativeNmeaSub;
  StreamSubscription? _nativeConstSub;

  final List<GnssSatellite> _satellites = [];
  final List<String> _nmeaSentences = [];
  Position? _lastPosition;

  // Observable streams
  final _satelliteController = StreamController<List<GnssSatellite>>.broadcast();
  final _nmeaController = StreamController<List<String>>.broadcast();
  final _dopController = StreamController<DopValues>.broadcast();

  Stream<List<GnssSatellite>> get satelliteStream => _satelliteController.stream;
  Stream<List<String>> get nmeaStream => _nmeaController.stream;
  Stream<DopValues> get dopStream => _dopController.stream;
  List<GnssSatellite> get satellites => List.unmodifiable(_satellites);
  List<String> get nmeaSentences => List.unmodifiable(_nmeaSentences);

  DopValues _currentDop = DopValues();
  DopValues get currentDop => _currentDop;

  bool _usingNative = false;
  bool get isUsingNative => _usingNative;

  /// Start GNSS monitoring
  /// First tries to connect to native Android GnssStatus.Callback via EventChannel.
  /// Falls back to realistic simulation if native channel is unavailable.
  Future<void> startMonitoring() async {
    // Always listen to position updates for location context
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen(_onPositionUpdate);

    // Try native EventChannel first (works on real Android devices)
    _tryNativeChannel();

    // If native didn't connect, simulation will kick in as fallback
    if (!_usingNative) {
      _startSimulationFallback();
    }
  }

  /// Try to connect to the native Android GNSS EventChannel
  void _tryNativeChannel() {
    try {
      // Attempt to listen to the native satellite stream
      // If there's no native listener registered, this will not emit anything
      // and we'll fall back to simulation
      _nativeSatSub = _satelliteChannel.receiveBroadcastStream().listen(
        (data) {
          if (data is List) {
            _usingNative = true;
            _onNativeSatellites(data);
          }
        },
        onError: (error) {
          debugPrint('Native GNSS channel error, using simulation: $error');
          _usingNative = false;
          _startSimulationFallback();
        },
        onDone: () {
          if (!_usingNative) _startSimulationFallback();
        },
        cancelOnError: false,
      );

      // Listen for native NMEA sentences
      _nativeNmeaSub = _nmeaChannel.receiveBroadcastStream().listen(
        (data) {
          if (data is List) {
            _onNativeNmea(data.cast<String>());
          }
        },
      );

      // Listen for constellation breakdown
      _nativeConstSub = _constellationChannel.receiveBroadcastStream().listen(
        (data) {
          if (data is Map) {
            _calculateDopFromNative();
          }
        },
      );

      // Timeout: if no native data within 5 seconds, fall back to simulation
      Timer(const Duration(seconds: 5), () {
        if (!_usingNative && (_simulationTimer == null || !_simulationTimer!.isActive)) {
          _startSimulationFallback();
        }
      });
    } catch (e) {
      debugPrint('Could not connect to native GNSS: $e');
      _usingNative = false;
      _startSimulationFallback();
    }
  }

  /// Process real satellite data from Android GnssStatus.Callback
  void _onNativeSatellites(List<dynamic> data) {
    final newSats = <GnssSatellite>[];

    for (final item in data) {
      if (item is Map) {
        newSats.add(GnssSatellite(
          prn: ((item['prn'] as num?)?.toInt() ?? 0),
          constellation: (item['constellation'] as String?) ?? 'Unknown',
          snr: (item['snr'] as num?)?.toDouble() ?? 0.0,
          elevation: (item['elevation'] as num?)?.toDouble() ?? 0.0,
          azimuth: (item['azimuth'] as num?)?.toDouble() ?? 0.0,
          usedInFix: (item['usedInFix'] as bool?) ?? false,
          hasEphemeris: (item['hasEphemeris'] as bool?) ?? false,
          hasAlmanac: (item['hasAlmanac'] as bool?) ?? false,
          frequencyBand: item['frequencyBand'] as String?,
        ));
      }
    }

    _satellites
      ..clear()
      ..addAll(newSats);
    _satelliteController.add(List.from(_satellites));

    // Calculate DOP from real satellite geometry
    _calculateDop();
  }

  /// Process real NMEA sentences from OnNmeaMessageListener
  void _onNativeNmea(List<String> sentences) {
    _nmeaSentences
      ..clear()
      ..addAll(sentences);
    _nmeaController.add(List.from(_nmeaSentences));
  }

  /// Fallback: Generate realistic simulated satellite data
  void _startSimulationFallback() {
    if (_simulationTimer != null && _simulationTimer!.isActive) return;

    debugPrint('Using simulated GNSS data (no native channel)');

    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_usingNative) return; // Native took over
      _generateSimulatedSatellites();
      _generateSimulatedNmea();
    });

    _nmeaTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_usingNative) return;
      _calculateDop();
    });
  }

  void _onPositionUpdate(Position pos) {
    _lastPosition = pos;
  }

  /// Generate realistic satellite data based on position quality
  void _generateSimulatedSatellites() {
    final random = math.Random(DateTime.now().millisecondsSinceEpoch ~/ 3000);
    final accuracy = _lastPosition?.accuracy ?? 10;
    final fixQuality = accuracy < 5 ? 1.0 : (accuracy < 15 ? 0.8 : (accuracy < 30 ? 0.6 : 0.3));

    final constellations = {
      'GPS':     { 'count': 7 + random.nextInt(5), 'prnBase': 1,  'snrBase': 32 },
      'GLONASS': { 'count': 4 + random.nextInt(4), 'prnBase': 65, 'snrBase': 28 },
      'Galileo': { 'count': 3 + random.nextInt(4), 'prnBase': 201,'snrBase': 30 },
      'BeiDou':  { 'count': 3 + random.nextInt(5), 'prnBase': 301,'snrBase': 26 },
      'QZSS':    { 'count': 1 + random.nextInt(2), 'prnBase': 193,'snrBase': 22 },
      'NavIC':   { 'count': 1 + random.nextInt(2), 'prnBase': 401,'snrBase': 20 },
    };

    final newSats = <GnssSatellite>[];
    var prnIdx = 0;

    for (final entry in constellations.entries) {
      final count = entry.value['count'] ?? 0;
      for (int i = 0; i < count && prnIdx < 40; i++) {
        prnIdx++;
        final baseSnr = (entry.value['snrBase'] as int).toDouble();
        final snr = (baseSnr + random.nextDouble() * 15 - 5) * fixQuality;
        final elevation = random.nextDouble() * 85;
        final azimuth = random.nextDouble() * 360;

        newSats.add(GnssSatellite(
          prn: (entry.value['prnBase'] ?? 0) + i,
          constellation: entry.key,
          snr: double.parse(snr.toStringAsFixed(1)),
          elevation: double.parse(elevation.toStringAsFixed(1)),
          azimuth: double.parse(azimuth.toStringAsFixed(1)),
          usedInFix: snr > 25 && random.nextDouble() > 0.15,
          hasEphemeris: snr > 20,
          hasAlmanac: true,
          frequencyBand: random.nextBool() ? 'L1' : 'L5',
        ));
      }
    }

    newSats.sort((a, b) => a.constellation.compareTo(b.constellation));
    _satellites
      ..clear()
      ..addAll(newSats);
    _satelliteController.add(List.from(_satellites));
  }

  /// Generate synthetic NMEA sentences for simulation fallback
  void _generateSimulatedNmea() {
    if (_lastPosition == null) return;

    final lat = _lastPosition!.latitude;
    final lng = _lastPosition!.longitude;
    final alt = _lastPosition!.altitude;
    final satsInView = _satellites.length;
    final satsUsed = _satellites.where((s) => s.usedInFix).length;
    final time = DateTime.now().toUtc();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}'
        '${time.minute.toString().padLeft(2, '0')}'
        '${time.second.toString().padLeft(2, '0')}.00';

    // $GPGGA
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    final latDeg = lat.abs();
    final lngDeg = lng.abs();
    final latD = latDeg.floor();
    final lngD = lngDeg.floor();
    final latMin = (latDeg - latD) * 60;
    final lngMin = (lngDeg - lngD) * 60;

    final ggastr = StringBuffer('\$GPGGA,')
      ..write('$timeStr,')
      ..write('${latD.toString().padLeft(2, '0')}${latMin.toStringAsFixed(4).padLeft(9, '0')},$latDir,')
      ..write('${lngD.toString().padLeft(3, '0')}${lngMin.toStringAsFixed(4).padLeft(9, '0')},$lngDir,')
      ..write('1,$satsUsed,${_currentDop.hdop.toStringAsFixed(1)},')
      ..write('${alt.toStringAsFixed(1)},M,0.0,M,,');
    final gpgga = '${ggastr.toString()}*${_checksum(ggastr.toString())}';

    // $GPGSA
    final satIds = _satellites.where((s) => s.usedInFix).map((s) => s.prn.toString()).toList();
    while (satIds.length < 12) satIds.add('');
    final gpsa = '\$GPGSA,A,3,${satIds.sublist(0, 12).join(',')},'
        '${_currentDop.pdop.toStringAsFixed(1)},'
        '${_currentDop.hdop.toStringAsFixed(1)},'
        '${_currentDop.vdop.toStringAsFixed(1)}*'
        '${_checksum('\$GPGSA,A,3,${satIds.sublist(0, 12).join(',')},'
        '${_currentDop.pdop.toStringAsFixed(1)},'
        '${_currentDop.hdop.toStringAsFixed(1)},'
        '${_currentDop.vdop.toStringAsFixed(1)}')}';

    // $GPGSV
    final gsvBuilder = StringBuffer('\$GPGSV,${(_satellites.length / 4).ceil()},1,$satsInView');
    for (int i = 0; i < _satellites.length && i < 4; i++) {
      final s = _satellites[i];
      gsvBuilder.write(',${s.prn},${s.elevation.toInt()},${s.azimuth.toInt()},${s.snr.toInt()}');
    }
    final gsv = '$gsvBuilder*${_checksum(gsvBuilder.toString().substring(1))}';

    _nmeaSentences
      ..clear()
      ..addAll([gpgga, gpsa, gsv]);
    _nmeaController.add(List.from(_nmeaSentences));
  }

  String _checksum(String sentence) {
    int ck = 0;
    for (int i = 0; i < sentence.length; i++) {
      if (i < sentence.length) ck ^= sentence.codeUnitAt(i);
    }
    return ck.toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  /// Calculate DOP values (Dilution of Precision) from satellite geometry
  void _calculateDop() {
    if (_satellites.isEmpty) return;

    final usedSats = _satellites.where((s) => s.usedInFix).toList();
    if (usedSats.length < 4) {
      _currentDop = DopValues(hdop: 99.9, vdop: 99.9, pdop: 99.9, tdop: 99.9);
      _dopController.add(_currentDop);
      return;
    }

    double sumCos2El = 0, sumSin2El = 0;
    double sumCos2Az = 0;

    for (final sat in usedSats) {
      final elRad = sat.elevation * math.pi / 180;
      final azRad = sat.azimuth * math.pi / 180;
      sumCos2El += math.cos(elRad) * math.cos(elRad);
      sumSin2El += math.sin(elRad) * math.sin(elRad);
      sumCos2Az += math.cos(azRad) * math.cos(azRad);
    }

    final n = usedSats.length.toDouble();
    final hdop = math.sqrt(n / (sumCos2El * (n - sumCos2Az)) * 1.5).clamp(0.5, 99.9);
    final vdop = math.sqrt(n / sumSin2El).clamp(0.5, 99.9);
    final pdop = math.sqrt(hdop * hdop + vdop * vdop).clamp(0.5, 99.9);
    final tdop = pdop * 0.4;

    _currentDop = DopValues(
      hdop: double.parse(hdop.toStringAsFixed(1)),
      vdop: double.parse(vdop.toStringAsFixed(1)),
      pdop: double.parse(pdop.toStringAsFixed(1)),
      tdop: double.parse(tdop.toStringAsFixed(1)),
    );
    _dopController.add(_currentDop);
  }

  /// Calculate DOP from native data (called after native constellation data arrives)
  void _calculateDopFromNative() {
    _calculateDop();
  }

  /// Get whether we're using real or simulated data
  String get dataSource => _usingNative ? 'Real (GnssStatus)' : 'Simulated';

  void stopMonitoring() {
    _nativeSatSub?.cancel();
    _nativeNmeaSub?.cancel();
    _nativeConstSub?.cancel();
    _positionStream?.cancel();
    _simulationTimer?.cancel();
    _nmeaTimer?.cancel();
    _usingNative = false;
    _satellites.clear();
    _nmeaSentences.clear();
  }

  void dispose() {
    stopMonitoring();
    _satelliteController.close();
    _nmeaController.close();
    _dopController.close();
  }
}

/// DOP (Dilution of Precision) values
class DopValues {
  final double hdop; // Horizontal
  final double vdop; // Vertical
  final double pdop; // Position (3D)
  final double tdop; // Time

  DopValues({
    this.hdop = 99.9,
    this.vdop = 99.9,
    this.pdop = 99.9,
    this.tdop = 99.9,
  });

  String get quality {
    if (pdop <= 1) return 'Ideal';
    if (pdop <= 2) return 'Excellent';
    if (pdop <= 5) return 'Good';
    if (pdop <= 10) return 'Moderate';
    if (pdop <= 20) return 'Fair';
    return 'Poor';
  }

  String get qualityColor {
    if (pdop <= 2) return '#4ADE80';
    if (pdop <= 5) return '#FBBF24';
    if (pdop <= 10) return '#F97316';
    return '#EF4444';
  }
}
