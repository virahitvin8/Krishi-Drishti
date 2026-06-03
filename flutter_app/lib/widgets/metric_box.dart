import 'package:flutter/material.dart';

/// Reusable metric box for displaying vegetation indices (NDVI, EVI, etc.)
class MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const MetricBox({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF71717A),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 9, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}
