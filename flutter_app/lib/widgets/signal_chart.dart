import 'package:flutter/material.dart';
import '../models/gnss_satellite.dart';

/// Signal strength bar chart — inspired by GPSTest and Google GNSS tools
/// Shows C/N0 (SNR) bars for each visible satellite, color-coded by constellation
class SignalChart extends StatelessWidget {
  final List<GnssSatellite> satellites;

  const SignalChart({super.key, required this.satellites});

  @override
  Widget build(BuildContext context) {
    if (satellites.isEmpty) {
      return const Center(
        child: Text('No satellites detected',
            style: TextStyle(color: Color(0xFF52525B), fontSize: 13)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text('PRN', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w500)),
              SizedBox(width: 8),
              Expanded(child: Text('C/N₀ (dB-Hz)', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w500))),
              SizedBox(width: 8),
              SizedBox(width: 40, child: Text('Used', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w500))),
            ],
          ),
        ),

        // Satellite rows
        ...satellites.take(20).map((sat) => _buildSatelliteRow(sat)),
      ],
    );
  }

  Widget _buildSatelliteRow(GnssSatellite sat) {
    final barWidth = (sat.snr / 50).clamp(0.0, 1.0);
    final color = Color(sat.constellationColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // PRN + constellation icon
          SizedBox(
            width: 60,
            child: Row(
              children: [
                Text(sat.constellationIcon, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '${sat.prn}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Signal bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: barWidth,
                backgroundColor: const Color(0xFF27272A),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 12,
              ),
            ),
          ),

          // SNR value
          SizedBox(
            width: 42,
            child: Text(
              sat.snr.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),

          // Used in fix indicator
          SizedBox(
            width: 40,
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sat.usedInFix
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
                      : const Color(0xFF27272A),
                  border: Border.all(
                    color: sat.usedInFix ? const Color(0xFF4ADE80) : const Color(0xFF52525B),
                    width: 1.5,
                  ),
                ),
                child: sat.usedInFix
                    ? const Icon(Icons.check, size: 12, color: Color(0xFF4ADE80))
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
