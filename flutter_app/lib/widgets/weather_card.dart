import 'package:flutter/material.dart';
import '../models/analysis.dart';

/// Weather data card showing temperature, humidity, precipitation, wind
class WeatherCard extends StatelessWidget {
  final Analysis analysis;
  const WeatherCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud, size: 18, color: Color(0xFF60A5FA)),
              SizedBox(width: 8),
              Text('Weather & Atmosphere',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF60A5FA))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _weatherItem(Icons.device_thermostat, '${analysis.temperatureC.toStringAsFixed(1)}°C', 'Temperature'),
              const SizedBox(width: 12),
              _weatherItem(Icons.water_drop, '${analysis.humidityPct.toStringAsFixed(0)}%', 'Humidity'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _weatherItem(Icons.water, '${analysis.precipitationMm.toStringAsFixed(1)}mm', 'Rain (48h)'),
              const SizedBox(width: 12),
              _weatherItem(Icons.air, '${analysis.windSpeedKmh.toStringAsFixed(1)}km/h', 'Wind'),
            ],
          ),
          if (analysis.forecastRain48h > 5) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF052E16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF166534)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.water_drop, color: Color(0xFF4ADE80), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Good rainfall expected — ideal for rainfed crops',
                        style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _weatherItem(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFA1A1AA)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14)),
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF71717A), fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
