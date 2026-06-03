import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/gnss_satellite.dart';

/// Raw GNSS data service - inspired by GPSTest and Google GPS Measurement Tools
/// On real Android devices, this would use android.hardware.gnss.GnssStatus
/// For cross-platform, we provide realistic satellite data from position info
class RawGnssService {
  static final RawGnssService _instance = RawGnssService._();
  factory RawGnssService() => _instance;
  RawGnssService._();

  StreamSubscription<Position>? _positionStream;
  Timer? _satelliteTimer;
  Timer? _nmeaTimer;

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

  /// Start GNSS monitoring with real satellite simulation
  Future<void> startMonitoring() async {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen(_onPositionUpdate);

    // Update satellite positions every 3 seconds (like real GPS receiver)
    _satelliteTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _generateRealisticSatellites();
      _generateNmeaSentences();
    });

    // Update DOP values every 5 seconds
    _nmeaTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _calculateDop();
    });
  }

  void _onPositionUpdate(Position pos) {
    _lastPosition = pos;
  }

  /// Generate realistic satellite data based on position quality
  void _generateRealisticSatellites() {
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
      for (int i = 0; i < entry.value['count'] && prnIdx < 40; i++) {
        prnIdx++;
        final baseSnr = (entry.value['snrBase'] as int).toDouble();
        final snr = (baseSnr + random.nextDouble() * 15 - 5) * fixQuality;
        final elevation = random.nextDouble() * 85;
        final azimuth = random.nextDouble() * 360;

        newSats.add(GnssSatellite(
          prn: entry.value['prnBase'] + i,
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

  /// Generate synthetic NMEA sentences
  void _generateNmeaSentences() {
    if (_lastPosition == null) return;

    final lat = _lastPosition!.latitude;
    final lng = _lastPosition!.longitude;
    final alt = _lastPosition!.altitude;
    final speed = _lastPosition!.speed;
    final heading = _lastPosition!.heading;
    final satsInView = _satellites.length;
    final satsUsed = _satellites.where((s) => s.usedInFix).length;
    final time = DateTime.now().toUtc();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}'
        '${time.minute.toString().padLeft(2, '0')}'
        '${time.second.toString().padLeft(2, '0')}.00';

    // $GPGGA - Fix data
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    final latDeg = lat.abs();
    final lngDeg = lng.abs();
    final latD = latDeg.floor();
    final lngD = lngDeg.floor();
    final latMin = (latDeg - latD) * 60;
    final lngMin = (lngDeg - lngD) * 60;

    final gpgga = '\$GPGGA,$timeStr,'
        '${latD.toString().padLeft(2, '0')}${latMin.toStringAsFixed(4).padLeft(9, '0')},$latDir,'
        '${lngD.toString().padLeft(3, '0')}${lngMin.toStringAsFixed(4).padLeft(9, '0')},$lngDir,'
        '1,$satsUsed,${_currentDop.hdop.toStringAsFixed(1)},'
        '${alt.toStringAsFixed(1)},M,0.0,M,,*'
        '${_checksum('\$GPGGA,$timeStr,'
        '${latD.toString().padLeft(2, '0')}${latMin.toStringAsFixed(4).padLeft(9, '0')},$latDir,'
        '${lngD.toString().padLeft(3, '0')}${lngMin.toStringAsFixed(4).padLeft(9, '0')},$lngDir,'
        '1,$satsUsed,${_currentDop.hdop.toStringAsFixed(1)},'
        '${alt.toStringAsFixed(1)},M,0.0,M,,')}';

    // $GPGSA - DOP and active satellites
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

    // $GPGSV - Satellites in view
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
      ck ^= sentence.codeUnitAt(i);
    }
    return ck.toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  /// Calculate DOP values (Dilution of Precision)
  void _calculateDop() {
    if (_satellites.isEmpty) return;

    final usedSats = _satellites.where((s) => s.usedInFix).toList();
    if (usedSats.length < 4) {
      _currentDop = DopValues(hdop: 99.9, vdop: 99.9, pdop: 99.9, tdop: 99.9);
      _dopController.add(_currentDop);
      return;
    }

    // Simplified DOP calculation based on satellite geometry
    double sumCos2El = 0, sumSin2El = 0;
    double sumCos2Az = 0, sumSin2Az = 0;

    for (final sat in usedSats) {
      final elRad = sat.elevation * math.pi / 180;
      final azRad = sat.azimuth * math.pi / 180;
      sumCos2El += math.cos(elRad) * math.cos(elRad);
      sumSin2El += math.sin(elRad) * math.sin(elRad);
      sumCos2Az += math.cos(azRad) * math.cos(azRad);
      sumSin2Az += math.sin(azRad) * math.sin(azRad);
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

  void stopMonitoring() {
    _positionStream?.cancel();
    _satelliteTimer?.cancel();
    _nmeaTimer?.cancel();
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
