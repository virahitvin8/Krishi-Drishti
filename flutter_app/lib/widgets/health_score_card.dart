import 'package:flutter/material.dart';
import '../models/analysis.dart';

/// Large health score display card with status and color coding
class HealthScoreCard extends StatelessWidget {
  final Analysis analysis;
  const HealthScoreCard({super.key, required this.analysis});

  Color get _healthColor {
    if (analysis.healthScore >= 80) return const Color(0xFF4ADE80);
    if (analysis.healthScore >= 65) return const Color(0xFFFBBF24);
    if (analysis.healthScore >= 50) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final color = _healthColor;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        children: [
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CROP HEALTH',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF71717A),
                      letterSpacing: 1,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${analysis.healthScore}',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text('/100',
                        style: TextStyle(
                            fontSize: 16, color: color.withValues(alpha: 0.5))),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(analysis.healthStatus,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Text('Sentinel-2 L2A',
                  style: TextStyle(
                      fontSize: 10, color: color.withValues(alpha: 0.5))),
              Text('10m resolution',
                  style: TextStyle(
                      fontSize: 10, color: color.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }
}
