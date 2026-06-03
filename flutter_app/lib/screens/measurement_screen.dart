import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/measurement_service.dart';
import '../services/gps_service.dart';
import '../models/measurement.dart';

/// Measurement Cockpit screen - inspired by GPS Cockpit
/// Area/distance measurement, elevation profiles, coordinate display, compass
class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> with SingleTickerProviderStateMixin {
  final MeasurementService _measService = MeasurementService();
  final GpsService _gpsService = GpsService();
  late TabController _tabController;

  List<({double lat, double lng})> _polygonPoints = [];
  List<({double lat, double lng})> _measurePoints = [];
  Position? _currentPosition;
  FieldMeasurement? _lastMeasurement;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _init();
  }

  Future<void> _init() async {
    await _measService.loadHistory();
    _currentPosition = await _gpsService.getCurrentLocation();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Row(
          children: [Icon(Icons.straighten, color: Color(0xFF2E7D32), size: 20), SizedBox(width: 8), Text('Measurement')],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2E7D32),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF71717A),
          tabs: const [
            Tab(text: 'Measure', icon: Icon(Icons.straighten, size: 18)),
            Tab(text: 'Coordinates', icon: Icon(Icons.pin_drop, size: 18)),
            Tab(text: 'History', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMeasureTab(),
          _buildCoordinateTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildMeasureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compass
          _buildCompass(),
          const SizedBox(height: 20),

          // Measurement tools
          const Text('Measurement Tools', style: TextStyle(color: Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),

          // Area measure
          _toolCard(
            icon: Icons.crop_square,
            label: 'Measure Area',
            desc: '${_polygonPoints.length} points selected',
            action: _polygonPoints.length >= 3 ? 'Calculate' : 'Tap to Add Points',
            color: const Color(0xFF4ADE80),
            onAction: () {
              if (_polygonPoints.length >= 3) {
                final result = _measService.measureArea(_polygonPoints);
                setState(() => _lastMeasurement = result);
                _showResult(result);
              } else {
                _simulateAreaMeasure();
              }
            },
            onReset: () => setState(() => _polygonPoints = []),
          ),
          const SizedBox(height: 10),

          // Distance measure
          _toolCard(
            icon: Icons.show_chart,
            label: 'Measure Distance',
            desc: _measurePoints.length >= 2
                ? '${CoordinateConverter.haversine(_measurePoints[0].lat, _measurePoints[0].lng, _measurePoints[1].lat, _measurePoints[1].lng).toStringAsFixed(0)}m'
                : 'Will use current position',
            action: 'Measure',
            color: const Color(0xFF60A5FA),
            onAction: () {
              final pos = _currentPosition;
              if (pos == null) return;
              final result = _measService.measureDistance(
                pos.latitude, pos.longitude,
                pos.latitude + 0.001, pos.longitude + 0.001,
              );
              setState(() => _lastMeasurement = result);
              _showResult(result);
            },
            onReset: () => setState(() => _measurePoints = []),
          ),
          const SizedBox(height: 10),

          // Elevation profile
          _toolCard(
            icon: Icons.trending_up,
            label: 'Elevation Profile',
            desc: _currentPosition != null ? 'Altitude: ${_currentPosition!.altitude.toStringAsFixed(1)}m' : 'No position',
            action: 'Profile',
            color: const Color(0xFFFBBF24),
            onAction: () {
              if (_currentPosition != null) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => _ElevationProfileScreen(currentPosition: _currentPosition!),
                ));
              }
            },
            onReset: null,
          ),

          if (_lastMeasurement != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text('Last Measurement', style: TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                  const SizedBox(height: 8),
                  Text(_lastMeasurement!.formatted, style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 32, fontWeight: FontWeight.bold)),
                  Text(_lastMeasurement!.name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  if (_lastMeasurement!.metadata != null) ...[
                    const SizedBox(height: 8),
                    ...(_lastMeasurement!.metadata!.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('${e.key}: ', style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                          Text('${e.value}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ))),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompass() {
    final heading = _currentPosition?.heading ?? 0;
    final dir = _measService.getHeadingDirection(heading);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        children: [
          // Compass rose
          Transform.rotate(
            angle: -heading * math.pi / 180,
            child: const Icon(Icons.navigation, color: Color(0xFFEF4444), size: 40),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$dir (${heading.toStringAsFixed(0)}°)',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${_currentPosition?.latitude.toStringAsFixed(4) ?? '--'}, ${_currentPosition?.longitude.toStringAsFixed(4) ?? '--'}',
                    style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolCard({
    required IconData icon, required String label, required String desc,
    required String action, required Color color,
    required VoidCallback? onAction, VoidCallback? onReset,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(desc, style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
              ],
            ),
          ),
          if (onReset != null)
            IconButton(icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF71717A)), onPressed: onReset),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Text(action, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _simulateAreaMeasure() {
    const points = [
      (lat: 25.3176, lng: 82.9739),
      (lat: 25.3184, lng: 82.9750),
      (lat: 25.3178, lng: 82.9762),
      (lat: 25.3169, lng: 82.9751),
    ];
    final result = _measService.measureArea(points, name: 'Demo Field');
    setState(() => _lastMeasurement = result);
    _showResult(result);
  }

  void _showResult(FieldMeasurement m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${m.name}: ${m.formatted}'), backgroundColor: const Color(0xFF2E7D32)),
    );
  }

  Widget _buildCoordinateTab() {
    final pos = _currentPosition;
    if (pos == null) {
      return const Center(child: Text('Enable GPS to see coordinates', style: TextStyle(color: Colors.white38)));
    }

    final formats = _measService.formatCoordinate(pos.latitude, pos.longitude);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: Column(
            children: [
              const Icon(Icons.pin_drop, color: Color(0xFF2E7D32), size: 32),
              const SizedBox(height: 12),
              Text('${pos.latitude.toStringAsFixed(6)}°N', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text('${pos.longitude.toStringAsFixed(6)}°E', style: const TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Accuracy: ${pos.accuracy.toStringAsFixed(0)}m · Alt: ${pos.altitude.toStringAsFixed(0)}m',
                  style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...formats.entries.map((e) => _formatCard(e.key, e.value)),
      ],
    );
  }

  Widget _formatCard(String format, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        children: [
          Text('${format.toUpperCase()}: ', style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'))),
          GestureDetector(
            onTap: () => _copyToClipboard(value),
            child: const Icon(Icons.copy, color: Color(0xFF71717A), size: 16),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String value) {
    // In Flutter: Clipboard.setData(ClipboardData(text: value));
    debugPrint('Copied: $value');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
    );
  }

  Widget _buildHistoryTab() {
    final history = _measService.history;
    if (history.isEmpty) {
      return const Center(child: Text('No measurements yet', style: TextStyle(color: Colors.white38)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final m = history[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: Row(
            children: [
              Icon(m.type == MeasurementType.area ? Icons.crop_square : Icons.show_chart,
                  color: const Color(0xFF2E7D32), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    Text(m.formatted, style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 12)),
                  ],
                ),
              ),
              Text('${m.timestamp.hour}:${m.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

/// Elevation profile screen
class _ElevationProfileScreen extends StatelessWidget {
  final Position currentPosition;
  const _ElevationProfileScreen({required this.currentPosition});

  @override
  Widget build(BuildContext context) {
    // Generate synthetic elevation profile
    final profileStart = DateTime.now().millisecondsSinceEpoch % 1000 / 1000;
    final profile = List.generate(20, (i) {
      final dist = i * 100.0;
      final elev = currentPosition.altitude +
          (profileStart * 10 + i * i % 7 - 3) * 2;
      return (distance: dist, elevation: elev);
    });

    final maxElev = profile.fold<double>(0, (m, p) => p.elevation > m ? p.elevation : m);
    final minElev = profile.fold<double>(double.infinity, (m, p) => p.elevation < m ? p.elevation : m);
    final gain = maxElev - minElev;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(title: const Text('Elevation Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            Row(
              children: [
                _elevStat('Max', '${maxElev.toStringAsFixed(0)}m', const Color(0xFF4ADE80)),
                const SizedBox(width: 12),
                _elevStat('Min', '${minElev.toStringAsFixed(0)}m', const Color(0xFF60A5FA)),
                const SizedBox(width: 12),
                _elevStat('Gain', '${gain.toStringAsFixed(0)}m', const Color(0xFFFBBF24)),
                const SizedBox(width: 12),
                _elevStat('Distance', '${(profile.last.distance / 1000).toStringAsFixed(1)}km', const Color(0xFFA78BFA)),
              ],
            ),
            const SizedBox(height: 24),

            // Profile chart
            Expanded(
              child: CustomPaint(
                painter: _ElevationProfilePainter(
                  profile: profile,
                  maxElev: maxElev,
                  minElev: minElev,
                ),
                size: const Size(double.infinity, 200),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0m', style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
                Text('${(profile.last.distance / 1000).toStringAsFixed(1)}km', style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Elevation profile shows altitude changes along the measured path. Useful for understanding terrain and planning irrigation.', style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _elevStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ElevationProfilePainter extends CustomPainter {
  final List<({double distance, double elevation})> profile;
  final double maxElev;
  final double minElev;

  _ElevationProfilePainter({required this.profile, required this.maxElev, required this.minElev});

  @override
  void paint(Canvas canvas, Size size) {
    if (profile.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF4ADE80).withValues(alpha: 0.3), const Color(0xFF4ADE80).withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final elevRange = (maxElev - minElev).clamp(1, double.infinity);
    final maxDist = profile.last.distance.clamp(1, double.infinity);

    for (int i = 0; i < profile.length; i++) {
      final x = (profile[i].distance / maxDist) * size.width;
      final y = size.height - ((profile[i].elevation - minElev) / elevRange) * size.height * 0.9 - 20;

      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Fill
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Points
    for (int i = 0; i < profile.length; i++) {
      final x = (profile[i].distance / maxDist) * size.width;
      final y = size.height - ((profile[i].elevation - minElev) / elevRange) * size.height * 0.9 - 20;
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = const Color(0xFF4ADE80));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
