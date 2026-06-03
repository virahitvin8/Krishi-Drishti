import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/gnss_satellite.dart';

/// Sky plot widget showing satellite positions (elevation/azimuth) — inspired by GPSTest
/// Shows satellites as colored dots on concentric circles representing elevation angles
class SkyPlot extends StatelessWidget {
  final List<GnssSatellite> satellites;
  final double size;

  const SkyPlot({
    super.key,
    required this.satellites,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SkyPlotPainter(satellites),
        size: Size(size, size),
      ),
    );
  }
}

class _SkyPlotPainter extends CustomPainter {
  final List<GnssSatellite> satellites;

  _SkyPlotPainter(this.satellites);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final paint = Paint();

    // Draw elevation circles (horizon at 0°, center at 90°)
    for (int i = 1; i <= 3; i++) {
      final r = radius * (1 - i * 0.25);
      paint.color = const Color(0xFF27272A);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1;
      canvas.drawCircle(center, r, paint);

      // Elevation labels
      final labelPainter = TextPainter(
        text: TextSpan(
          text: '${i * 30}°',
          style: const TextStyle(color: Color(0xFF52525B), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(center.dx + r + 4, center.dy - 6));
    }

    // Draw cardinal direction lines
    final dirPaint = Paint()
      ..color = const Color(0xFF27272A)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius),
        dirPaint,
      );
    }

    // Direction labels
    final dirs = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final labelPainter = TextPainter(
        text: TextSpan(
          text: dirs[i],
          style: const TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          center.dx + math.cos(angle) * (radius + 16) - labelPainter.width / 2,
          center.dy + math.sin(angle) * (radius + 16) - labelPainter.height / 2,
        ),
      );
    }

    // Draw satellites
    for (final sat in satellites) {
      final azimRad = sat.azimuth * math.pi / 180;
      final distFromCenter = radius * (1 - sat.elevation / 90);
      
      final x = center.dx + math.sin(azimRad) * distFromCenter;
      final y = center.dy - math.cos(azimRad) * distFromCenter;

      // Size based on SNR
      final dotRadius = 4.0 + (sat.snr / 40) * 4;
      final color = Color(sat.constellationColor);

      // Glow effect
      if (sat.usedInFix) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(x, y), dotRadius + 4, glowPaint);
      }

      // Satellite dot
      final dotPaint = Paint()
        ..color = color.withValues(alpha: sat.usedInFix ? 1.0 : 0.5);
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);

      // PRN label
      if (sat.snr > 20) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: '${sat.constellation.substring(0, math.min(2, sat.constellation.length))}${sat.prn}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        labelPainter.layout();
        labelPainter.paint(canvas, Offset(x - labelPainter.width / 2, y + dotRadius + 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPlotPainter oldDelegate) => true;
}
