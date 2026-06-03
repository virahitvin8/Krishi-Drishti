import 'package:flutter/material.dart';
import '../models/analysis.dart';

/// Detailed multi-satellite report screen
class ReportScreen extends StatelessWidget {
  final Analysis analysis;
  const ReportScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Full Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
            tooltip: 'Share',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildSection(
              title: 'Vegetation Health Analysis',
              icon: Icons.eco,
              color: const Color(0xFF4ADE80),
              child: Column(
                children: [
                  _buildMetricRow('NDVI', analysis.ndvi, 0.8, '%'),
                  _buildMetricRow('EVI', analysis.evi, 0.8, '%'),
                  _buildMetricRow('NDWI', analysis.ndwi + 0.5, 1.5, '%'),
                  _buildMetricRow('GNDVI', analysis.gndvi, 0.8, '%'),
                  _buildMetricRow('REIP', analysis.reip, 0.6, '%'),
                  _buildMetricRow('SAVI', analysis.savi, 0.7, '%'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Soil
            _buildSection(
              title: 'Soil & Moisture Analysis',
              icon: Icons.water_drop,
              color: const Color(0xFF60A5FA),
              child: Column(
                children: [
                  _buildInfoRow('Surface Moisture',
                      '${analysis.soilMoisturePct.toStringAsFixed(1)}%'),
                  _buildInfoRow('Drainage Score',
                      '${analysis.drainageScore}/100'),
                  _buildInfoRow('Organic Matter',
                      '${(2.0 + analysis.latitude / 40).toStringAsFixed(1)}%'),
                  _buildInfoRow('Water Stress',
                      analysis.soilMoisturePct < 15 ? 'High' : 'Low'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Weather
            _buildSection(
              title: 'Weather & Atmosphere',
              icon: Icons.cloud,
              color: const Color(0xFFFBBF24),
              child: Column(
                children: [
                  _buildInfoRow('Temperature',
                      '${analysis.temperatureC.toStringAsFixed(1)}°C'),
                  _buildInfoRow('Humidity',
                      '${analysis.humidityPct.toStringAsFixed(1)}%'),
                  _buildInfoRow('Precipitation',
                      '${analysis.precipitationMm.toStringAsFixed(1)} mm'),
                  _buildInfoRow('Wind Speed',
                      '${analysis.windSpeedKmh.toStringAsFixed(1)} km/h'),
                  _buildInfoRow('Solar Radiation',
                      '${analysis.solarRadiationMj.toStringAsFixed(1)} MJ/m²'),
                  _buildInfoRow('Evapotranspiration',
                      '${analysis.evapotranspirationMm.toStringAsFixed(1)} mm'),
                  _buildInfoRow('Rain 48h Forecast',
                      '${analysis.forecastRain48h.toStringAsFixed(1)} mm'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Pest Risk
            _buildSection(
              title: 'Pest & Disease Risk',
              icon: Icons.bug_report,
              color: analysis.pestRiskScore < 30
                  ? const Color(0xFF4ADE80)
                  : analysis.pestRiskScore < 60
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFEF4444),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${analysis.pestRiskScore}/100',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(width: 12),
                      Text(analysis.pestRiskLevel,
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Based on: REIP + humidity + temperature + NDVI',
                      style: TextStyle(color: Color(0xFF52525B), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Satellite Sources
            _buildSection(
              title: 'Satellite Data Sources',
              icon: Icons.satellite_alt,
              color: const Color(0xFFA78BFA),
              child: Column(
                children: [
                  _buildSatelliteSource('Sentinel-2', 'ESA Copernicus',
                      '10m', 'NDVI, EVI, NDWI, GNDVI, REIP, SAVI'),
                  const Divider(color: Color(0xFF27272A)),
                  _buildSatelliteSource('Sentinel-1 SAR', 'ESA Copernicus',
                      '10m', 'Soil moisture, flood detection'),
                  const Divider(color: Color(0xFF27272A)),
                  _buildSatelliteSource('Landsat 8/9', 'NASA/USGS',
                      '30m', 'Long-term vegetation trends'),
                  const Divider(color: Color(0xFF27272A)),
                  _buildSatelliteSource('NASA POWER', 'NASA',
                      'Weather', 'Temperature, precipitation, solar'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Recommendations
            if (analysis.recommendations.isNotEmpty)
              _buildSection(
                title: 'Recommendations',
                icon: Icons.lightbulb_outline,
                color: const Color(0xFFF97316),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: analysis.recommendations.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(color: Color(0xFFA1A1AA))),
                        Expanded(
                          child: Text(r,
                              style: const TextStyle(
                                  color: Color(0xFFD4D4D8), fontSize: 13)),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, double value, double maxVal, String unit) {
    final pct = ((value / maxVal) * 100).clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 60,
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFFA1A1AA), fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: const Color(0xFF27272A),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text('${(value * 100).toInt()}$unit',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSatelliteSource(
      String name, String agency, String resolution, String indices) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          Text('$agency • ${resolution}resolution',
              style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
          Text(indices,
              style: const TextStyle(color: Color(0xFF52525B), fontSize: 11)),
        ],
      ),
    );
  }
}
