import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/raw_gnss_service.dart';
import '../services/gps_service.dart';
import '../models/gnss_satellite.dart';

/// Advanced NMEA + GNSS status screen - inspired by GPSTest and Google GPS Measurement Tools
/// Shows raw NMEA sentences, DOP values, satellite constellations, and fix quality
class NmeaScreen extends StatefulWidget {
  const NmeaScreen({super.key});

  @override
  State<NmeaScreen> createState() => _NmeaScreenState();
}

class _NmeaScreenState extends State<NmeaScreen> with SingleTickerProviderStateMixin {
  final RawGnssService _gnssService = RawGnssService();
  final GpsService _gpsService = GpsService();
  late TabController _tabController;

  List<GnssSatellite> _satellites = [];
  List<String> _nmeaSentences = [];
  DopValues _dop = DopValues();
  Position? _position;
  StreamSubscription? _satSub, _nmeaSub, _dopSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startMonitoring();
  }

  void _startMonitoring() async {
    await _gpsService.requestPermission();
    _gnssService.startMonitoring();
    _position = await _gpsService.getCurrentLocation();

    _satSub = _gnssService.satelliteStream.listen((sats) {
      if (mounted) setState(() => _satellites = sats);
    });
    _nmeaSub = _gnssService.nmeaStream.listen((nmea) {
      if (mounted) setState(() => _nmeaSentences = nmea);
    });
    _dopSub = _gnssService.dopStream.listen((dop) {
      if (mounted) setState(() => _dop = dop);
    });
  }

  @override
  Widget build(BuildContext context) {
    final satsUsed = _satellites.where((s) => s.usedInFix).length;
    final satsVisible = _satellites.length;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.satellite_alt, color: Color(0xFF2E7D32), size: 20),
            SizedBox(width: 8),
            Text('GNSS Test'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2E7D32),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF71717A),
          tabs: const [
            Tab(text: 'Status', icon: Icon(Icons.gps_fixed, size: 18)),
            Tab(text: 'Sky Plot', icon: Icon(Icons.my_location, size: 18)),
            Tab(text: 'NMEA', icon: Icon(Icons.terminal, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatusTab(satsUsed, satsVisible),
          _buildSkyPlotTab(),
          _buildNmeaTab(),
        ],
      ),
    );
  }

  Widget _buildStatusTab(int satsUsed, int satsVisible) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fix status card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Row(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _dop.quality == 'Ideal' || _dop.quality == 'Excellent'
                        ? const Color(0xFF4ADE80).withValues(alpha: 0.15)
                        : _dop.quality == 'Good'
                            ? const Color(0xFFFBBF24).withValues(alpha: 0.15)
                            : const Color(0xFFEF4444).withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Text('$satsUsed', style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold,
                      color: _dop.quality == 'Ideal' || _dop.quality == 'Excellent'
                          ? const Color(0xFF4ADE80)
                          : _dop.quality == 'Good'
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFFEF4444),
                    )),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${satsUsed}/${satsVisible} Satellites',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Fix quality: ${_dop.quality}', style: TextStyle(
                        color: _dop.quality == 'Ideal' || _dop.quality == 'Excellent'
                            ? const Color(0xFF4ADE80)
                            : _dop.quality == 'Good'
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFEF4444),
                        fontSize: 13,
                      )),
                      if (_position != null) ...[
                        const SizedBox(height: 2),
                        Text('Accuracy: ${_position!.accuracy.toStringAsFixed(0)}m',
                            style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // DOP values grid
          const Text('Dilution of Precision', style: TextStyle(color: Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _dopBox('HDOP', _dop.hdop.toStringAsFixed(1), _dop.hdop <= 2 ? const Color(0xFF4ADE80) : _dop.hdop <= 5 ? const Color(0xFFFBBF24) : const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              _dopBox('VDOP', _dop.vdop.toStringAsFixed(1), _dop.vdop <= 2.5 ? const Color(0xFF4ADE80) : _dop.vdop <= 5 ? const Color(0xFFFBBF24) : const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _dopBox('PDOP', _dop.pdop.toStringAsFixed(1), _dop.pdop <= 2 ? const Color(0xFF4ADE80) : _dop.pdop <= 5 ? const Color(0xFFFBBF24) : const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              _dopBox('TDOP', _dop.tdop.toStringAsFixed(1), _dop.tdop <= 1 ? const Color(0xFF4ADE80) : _dop.tdop <= 2 ? const Color(0xFFFBBF24) : const Color(0xFFEF4444)),
            ],
          ),

          const SizedBox(height: 20),

          // Position info
          const Text('Position', style: TextStyle(color: Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Column(
              children: [
                _infoRow('Latitude', _position?.latitude.toStringAsFixed(6) ?? '--'),
                _infoRow('Longitude', _position?.longitude.toStringAsFixed(6) ?? '--'),
                _infoRow('Altitude', _position != null ? '${_position!.altitude.toStringAsFixed(1)}m' : '--'),
                _infoRow('Speed', _position != null ? '${(_position!.speed * 3.6).toStringAsFixed(1)} km/h' : '--'),
                _infoRow('Heading', _position != null ? '${_position!.heading.toStringAsFixed(1)}°' : '--'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Constellation breakdown
          const Text('Constellations', style: TextStyle(color: Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ..._buildConstellationBreakdown(),
        ],
      ),
    );
  }

  Widget _dopBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildConstellationBreakdown() {
    final breakdown = <String, int>{};
    for (final sat in _satellites) {
      breakdown[sat.constellation] = (breakdown[sat.constellation] ?? 0) + 1;
    }

    return breakdown.entries.map((e) => Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_constIcon(e.key), color: _constColor(e.key), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text('${e.value} sats', style: const TextStyle(color: Color(0xFF71717A), fontSize: 13)),
        ],
      ),
    )).toList();
  }

  Widget _buildSkyPlotTab() {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _NmeaSkyPlotPainter(satellites: _satellites),
            size: Size.infinite,
          ),
        ),
        // Legend
        Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: ['GPS', 'GLONASS', 'Galileo', 'BeiDou', 'QZSS', 'NavIC'].map((c) {
              final count = _satellites.where((s) => s.constellation == c).length;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _constColor(c),
                  )),
                  const SizedBox(width: 4),
                  Text('$c: $count', style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNmeaTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF18181B),
          child: Row(
            children: [
              Icon(Icons.terminal, color: const Color(0xFF4ADE80), size: 16),
              const SizedBox(width: 8),
              const Text('Raw NMEA Sentences', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_nmeaSentences.length} msgs', style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFF0D0D0D),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _nmeaSentences.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: Text(
                  _nmeaSentences[i],
                  style: const TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Color(0xFF71717A), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  IconData _constIcon(String constellation) {
    switch (constellation) {
      case 'GPS': return Icons.satellite;
      case 'GLONASS': return Icons.satellite;
      case 'Galileo': return Icons.science;
      case 'BeiDou': return Icons.near_me;
      default: return Icons.circle;
    }
  }

  Color _constColor(String constellation) {
    switch (constellation) {
      case 'GPS': return const Color(0xFF4ADE80);
      case 'GLONASS': return const Color(0xFF60A5FA);
      case 'Galileo': return const Color(0xFFFBBF24);
      case 'BeiDou': return const Color(0xFFEF4444);
      case 'QZSS': return const Color(0xFFA78BFA);
      case 'NavIC': return const Color(0xFFF97316);
      default: return const Color(0xFF71717A);
    }
  }  @override
  void dispose() {
    _tabController.dispose();
    _satSub?.cancel();
    _nmeaSub?.cancel();
    _dopSub?.cancel();
    _gnssService.dispose();
    super.dispose();
  }
}

/// Simple sky plot painter for NMEA screen
class _NmeaSkyPlotPainter extends CustomPainter {
  final List<GnssSatellite> satellites;

  _NmeaSkyPlotPainter({required this.satellites});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final paint = Paint();

    // Draw elevation circles
    for (int i = 1; i <= 3; i++) {
      final r = radius * (1 - i * 0.25);
      paint.color = const Color(0xFF27272A);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1;
      canvas.drawCircle(center, r, paint);
    }

    // Draw satellites
    for (final sat in satellites) {
      final azimRad = sat.azimuth * 3.14159 / 180;
      final distFromCenter = radius * (1 - sat.elevation / 90);

      final x = center.dx + math.sin(azimRad) * distFromCenter;
      final y = center.dy - math.cos(azimRad) * distFromCenter;
      final dotRadius = 4.0 + (sat.snr / 40) * 4;
      final color = Color(sat.constellationColor);

      final dotPaint = Paint()
        ..color = color.withValues(alpha: sat.usedInFix ? 1.0 : 0.5);
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NmeaSkyPlotPainter oldDelegate) => true;
}


