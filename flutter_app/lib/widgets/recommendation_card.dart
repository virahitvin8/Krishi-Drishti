import 'package:flutter/material.dart';

/// Individual recommendation card
class RecommendationCard extends StatelessWidget {
  final String text;
  const RecommendationCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.startsWith('⚠️') ? '⚠️' : '•',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.replaceAll(RegExp(r'^[⚠️✅💧🌿🌊🌱🐛☀️❄️🌧️📊🔄\s]+'), ''),
              style: const TextStyle(
                color: Color(0xFFD4D4D8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
