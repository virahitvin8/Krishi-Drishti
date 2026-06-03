import 'package:flutter/material.dart';
import 'gnss_status_screen.dart';
import 'track_recorder_screen.dart';
import 'nmea_screen.dart';
import 'geofence_screen.dart';
import 'survey_screen.dart';
import 'measurement_screen.dart';
import 'satellite_overlay_screen.dart';

/// Tools screen showing a grid of all GPS/satellite tools
/// All features are now fully implemented
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.build_outlined, color: Color(0xFF2E7D32), size: 20),
            SizedBox(width: 8),
            Text('GPS & Satellite Tools'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Field Tools',
                style: TextStyle(color: Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _toolCard(
                    context,
                    icon: Icons.satellite_alt,
                    label: 'GNSS Status',
                    description: 'Satellite sky plot, signal strength, constellation tracking',
                    color: const Color(0xFF4ADE80),
                    screen: const GnssStatusScreen(),
                  ),
                  _toolCard(
                    context,
                    icon: Icons.gps_fixed,
                    label: 'GPS Test',
                    description: 'NMEA viewer, DOP values, fix quality, constellations',
                    color: const Color(0xFFFBBF24),
                    screen: const NmeaScreen(),
                  ),
                  _toolCard(
                    context,
                    icon: Icons.route,
                    label: 'Track Recorder',
                    description: 'GPS track logging, waypoints, GPX export',
                    color: const Color(0xFF60A5FA),
                    screen: const TrackRecorderScreen(),
                  ),
                  _toolCard(
                    context,
                    icon: Icons.fence,
                    label: 'Geofencing',
                    description: 'Field boundary alerts, enter/leave notifications, zones',
                    color: const Color(0xFFA78BFA),
                    screen: const GeofenceScreen(),
                  ),
                  _toolCard(
                    context,
                    icon: Icons.assignment,
                    label: 'Field Survey',
                    description: 'Structured forms, photo capture, voice notes, offline sync',
                    color: const Color(0xFFF97316),
                    screen: const SurveyScreen(),
                  ),
                  _toolCard(
                    context,
                    icon: Icons.straighten,
                    label: 'Measurement',
                    description: 'Area, distance, elevation profile, coordinate formats',
                    color: const Color(0xFF34D399),
                    screen: const MeasurementScreen(),
                  ),
                  _toolCard(
                    context,
                    icon: Icons.satellite,
                    label: 'Satellite Imagery',
                    description: 'Scene browser, NDVI overlay, historical comparison',
                    color: const Color(0xFF14B8A6),
                    screen: const SatelliteOverlayScreen(),
                  ),
                  _toolCard(
                    context,
                    icon: Icons.share,
                    label: 'Live Tracking',
                    description: 'Real-time position sharing with auto-upload',
                    color: const Color(0xFFE11D48),
                    screen: null, // Built into Track Recorder - access via Enhanced Tracking settings
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required Widget? screen,
  }) {
    return GestureDetector(
      onTap: screen != null
          ? () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => screen))
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label — available in Track Recorder settings'),
                  backgroundColor: color,
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: screen != null ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 22),
              ),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(color: Color(0xFF71717A), fontSize: 10), maxLines: 2),
          ],
        ),
      ),
    );
  }
}
