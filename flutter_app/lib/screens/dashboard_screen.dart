import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/analysis.dart';
import '../services/api_service.dart';
import 'csv_upload_screen.dart';
import 'report_screen.dart';
import '../widgets/metric_box.dart';
import '../widgets/health_score_card.dart';
import '../widgets/weather_card.dart';
import '../widgets/recommendation_card.dart';
import 'dart:async';

/// Main dashboard showing crop health, weather, pest risk, recommendations
class DashboardScreen extends StatefulWidget {
  final AppUser? user;
  const DashboardScreen({super.key, this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Analysis? _analysis;
  bool _loading = false;
  String _lastUpdated = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _analysis = ApiService().generateMockAnalysis(25.3176, 82.9739);
    _updateTimestamp();
    // Auto-refresh display every 30s
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateTimestamp();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _updateTimestamp() {
    final now = DateTime.now();
    setState(() {
      _lastUpdated =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _analyzeField(double lat, double lng) async {
    setState(() => _loading = true);
    try {
      final result = await ApiService().analyzeField(
        latitude: lat,
        longitude: lng,
      );
      setState(() => _analysis = result);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _analysis;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.satellite_alt_rounded,
                  size: 18, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Krishi Drishti',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('कृषि दृष्टि',
                    style:
                        TextStyle(fontSize: 10, color: Color(0xFF4ADE80))),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF2E7D32),
                child: Text(
                  widget.user!.displayName[0].toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: () => _analyzeField(
          a?.latitude ?? 25.3176,
          a?.longitude ?? 82.9739,
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status bar
              Row(
                children: [
                  const Icon(Icons.satellite_alt, size: 12, color: Color(0xFF52525B)),
                  const SizedBox(width: 6),
                  Text(
                    'Updated $_lastUpdated',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF52525B)),
                  ),
                  const SizedBox(width: 12),
                  if (_loading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // === HEALTH SCORE ===
              if (a != null) HealthScoreCard(analysis: a),

              const SizedBox(height: 16),

              // === METRICS GRID ===
              Row(
                children: [
                  Expanded(
                    child: MetricBox(
                      label: 'NDVI',
                      value: a != null ? '${(a.ndvi * 100).toInt()}%' : '--',
                      subtitle: 'Vegetation health',
                      color: const Color(0xFF4ADE80),
                      onTap: () => _showMetricInfo('NDVI',
                          'Normalized Difference Vegetation Index measures crop vigor.'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricBox(
                      label: 'EVI',
                      value: a != null ? '${(a.evi * 100).toInt()}%' : '--',
                      subtitle: 'Canopy structure',
                      color: const Color(0xFF4ADE80),
                      onTap: () => _showMetricInfo('EVI',
                          'Enhanced Vegetation Index for dense canopy analysis.'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricBox(
                      label: 'NDWI',
                      value: a != null ? '${(a.ndwi * 100).toInt()}%' : '--',
                      subtitle: 'Water content',
                      color: const Color(0xFF60A5FA),
                      onTap: () => _showMetricInfo('NDWI',
                          'Normalized Difference Water Index measures crop water.'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: MetricBox(
                      label: 'REIP',
                      value: a != null ? '${(a.reip * 100).toInt()}%' : '--',
                      subtitle: 'Early stress',
                      color: const Color(0xFFFBBF24),
                      onTap: () => _showMetricInfo('REIP',
                          'Red Edge Inflection Point detects stress before visible.'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricBox(
                      label: 'SAVI',
                      value: a != null ? '${(a.savi * 100).toInt()}%' : '--',
                      subtitle: 'Soil adjusted',
                      color: const Color(0xFF4ADE80),
                      onTap: () => _showMetricInfo('SAVI',
                          'Soil Adjusted Vegetation Index for sparse vegetation.'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricBox(
                      label: 'GNDVI',
                      value: a != null ? '${(a.gndvi * 100).toInt()}%' : '--',
                      subtitle: 'Chlorophyll',
                      color: const Color(0xFF4ADE80),
                      onTap: () => _showMetricInfo('GNDVI',
                          'Green NDVI measures chlorophyll content.'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // === PEST RISK + DRAINAGE ===
              if (a != null)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        icon: Icons.bug_report_outlined,
                        label: 'Pest Risk',
                        value: '${a.pestRiskScore}',
                        maxValue: '100',
                        color: a.pestRiskScore < 30
                            ? const Color(0xFF4ADE80)
                            : a.pestRiskScore < 60
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFEF4444),
                        subtitle: a.pestRiskLevel,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusCard(
                        icon: Icons.water_drop_outlined,
                        label: 'Drainage',
                        value: '${a.drainageScore}',
                        maxValue: '100',
                        color: a.drainageScore >= 60
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFFFBBF24),
                        subtitle: a.drainageScore >= 60
                            ? 'Well drained'
                            : 'Needs improvement',
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // === WEATHER ===
              if (a != null) WeatherCard(analysis: a),

              const SizedBox(height: 20),

              // === RECOMMENDATIONS ===
              if (a != null && a.recommendations.isNotEmpty) ...[
                const Text('Recommendations',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 12),
                ...a.recommendations
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RecommendationCard(text: r),
                        )),
              ],

              const SizedBox(height: 24),

              // === ACTION BUTTONS ===
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.assessment_outlined,
                      label: 'Full Report',
                      onTap: () => _analysis != null
                          ? Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReportScreen(analysis: _analysis!),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.upload_file_outlined,
                      label: 'Upload CSV',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CsvUploadScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required String value,
    required String maxValue,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF71717A))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/$maxValue',
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF52525B))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _showMetricInfo(String name, String description) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text(description,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFFA1A1AA))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
