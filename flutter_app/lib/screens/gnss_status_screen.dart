import 'dart:async';
import 'package:flutter/material.dart';
import '../services/gnss_service.dart';
import '../models/gnss_satellite.dart';
import '../widgets/sky_plot.dart';
import '../widgets/signal_chart.dart';

/// GNSS Satellite Status Screen — inspired by GPSTest, Google GPS Measurement Tools
/// Shows: sky plot, signal strength chart, constellation breakdown, location stats
class GnssStatusScreen extends StatefulWidget {
  const GnssStatusScreen({super.key});

  @override
  State<GnssStatusScreen> createState() => _GnssStatusScreenState();
}

class _GnssStatusScreenState extends State<GnssStatusScreen>
    with SingleTickerProviderStateMixin {
  final GnssService _gnss = GnssService();
  List<GnssSatellite> _satellites = [];
  GnssStats _stats = GnssStats();
  late TabController _tabController;
  StreamSubscription? _satSub;
  StreamSubscription? _statsSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startMonitoring();
  }

  void _startMonitoring() {
    _gnss.startMonitoring();
    _satSub = _gnss.satelliteStream.listen((sats) {
      if (mounted) setState(() => _satellites = sats);
    });
    _statsSub = _gnss.statsStream.listen((stats) {
      if (mounted) setState(() => _stats = stats);
    });
  }

  @override
  void dispose() {
    _satSub?.cancel();
    _statsSub?.cancel();
    _gnss.stopMonitoring();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.satellite_alt, color: Color(0xFF2E7D32), size: 20),
            const SizedBox(width: 8),
            const Text('GNSS Status'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
              ),
              child: Text(
                '${_satellites.length} sats',
                style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2E7D32),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF71717A),
          tabs: const [
            Tab(text: 'Sky Plot', icon: Icon(Icons.my_location, size: 16)),
            Tab(text: 'Signals', icon: Icon(Icons.graphic_eq, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSkyPlotTab(),
          _buildSignalsTab(),
        ],
      ),
    );
  }

  Widget _buildSkyPlotTab() {
    final breakdown = _gnss.getConstellationBreakdown();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Center(child: SkyPlot(satellites: _satellites, size: 300)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Row(
              children: [
                _statBox('Visible', '${_stats.visibleCount}', const Color(0xFF4ADE80)),
                _statBox('In Use', '${_stats.satelliteCount}', const Color(0xFF60A5FA)),
                _statBox('Accuracy', '${_stats.accuracy?.toStringAsFixed(0) ?? '--'}m', const Color(0xFFFBBF24)),
                _statBox('Speed', _stats.speed != null ? '${(_stats.speed! * 3.6).toStringAsFixed(0)}km/h' : '--', const Color(0xFFA78BFA)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_stats.latitude != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Position', style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_stats.formattedLatitude,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        child: Text(_stats.formattedLongitude,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (_stats.altitude != null) ...[
                    const SizedBox(height: 4),
                    Text('Alt: ${_stats.altitude!.toStringAsFixed(1)}m MSL',
                        style: const TextStyle(color: Color(0xFF52525B), fontSize: 12)),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Constellations', style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                const SizedBox(height: 12),
                ...breakdown.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      _constellationIcon(e.key),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _constellationColor(e.key).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${e.value} sats',
                            style: TextStyle(color: _constellationColor(e.key), fontSize: 11)),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSignalsTab() {
    final sorted = List<GnssSatellite>.from(_satellites);
    sorted.sort((a, b) => b.snr.compareTo(a.snr));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Signal Quality — C/N₀ (dB-Hz)',
                    style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _qualityBadge('Excellent', '≥ 40', const Color(0xFF4ADE80)),
                    const SizedBox(width: 6),
                    _qualityBadge('Good', '30-40', const Color(0xFF60A5FA)),
                    const SizedBox(width: 6),
                    _qualityBadge('Fair', '20-30', const Color(0xFFFBBF24)),
                    const SizedBox(width: 6),
                    _qualityBadge('Weak', '< 20', const Color(0xFFEF4444)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Top Signals', style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Column(
              children: [
                ...sorted.take(5).map((sat) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Color(sat.constellationColor).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(child: Text(sat.constellationIcon, style: const TextStyle(fontSize: 14))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${sat.constellation} ${sat.prn}',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                            Text('El: ${sat.elevation.toStringAsFixed(1)}° Az: ${sat.azimuth.toStringAsFixed(1)}°',
                                style: const TextStyle(color: Color(0xFF52525B), fontSize: 10)),
                          ],
                        ),
                      ),
                      Text('${sat.snr.toStringAsFixed(1)} dB-Hz',
                          style: TextStyle(color: Color(sat.constellationColor), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
                if (sorted.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('+ ${sorted.length - 5} more satellites',
                        style: const TextStyle(color: Color(0xFF52525B), fontSize: 11)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('All Signals', style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: SignalChart(satellites: sorted),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF71717A))),
        ],
      ),
    );
  }

  Widget _qualityBadge(String label, String range, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
            Text(range, style: const TextStyle(color: Color(0xFF71717A), fontSize: 8)),
          ],
        ),
      ),
    );
  }

  Widget _constellationIcon(String name) {
    final icons = {
      'GPS': '\u{1F1FA}\u{1F1F8}', 'GLONASS': '\u{1F1F7}\u{1F1FA}',
      'Galileo': '\u{1F1EA}\u{1F1FA}', 'BeiDou': '\u{1F1E8}\u{1F1F3}',
      'QZSS': '\u{1F1EF}\u{1F1F5}', 'NavIC': '\u{1F1EE}\u{1F1F3}', 'SBAS': '\u{1F6F0}\uFE0F',
    };
    return Text(icons[name] ?? '\u{1F6F0}\uFE0F', style: const TextStyle(fontSize: 18));
  }

  Color _constellationColor(String name) {
    final colors = {
      'GPS': const Color(0xFF4ADE80), 'GLONASS': const Color(0xFF60A5FA),
      'Galileo': const Color(0xFFFBBF24), 'BeiDou': const Color(0xFFF97316),
      'QZSS': const Color(0xFFA78BFA), 'NavIC': const Color(0xFFEF4444),
    };
    return colors[name] ?? const Color(0xFF71717A);
  }
}
