import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/gps_service.dart';
import '../services/api_service.dart';
import '../models/analysis.dart';

/// Interactive map with GPS positioning, field selection, and hotspot grid
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final GpsService _gpsService = GpsService();
  final ApiService _apiService = ApiService();

  LatLng _center = const LatLng(25.3176, 82.9739);
  bool _loading = false;
  bool _gridVisible = true;
  bool _gpsActive = false;
  Analysis? _analysis;
  List<LatLng> _fieldPolygon = [];
  List<Polygon> _gridPolygons = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // Try getting GPS location
    final pos = await _gpsService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
        _gpsActive = true;
      });
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_center, 16);
        });
      }
    }
  }

  /// Get current GPS position and center map
  Future<void> _centerOnGps() async {
    final pos = await _gpsService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
        _gpsActive = true;
        _fieldPolygon = [];
        _gridPolygons = [];
        _analysis = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_center, 17);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS not available. Enable location services.')),
        );
      }
    }
  }

  /// Create a demo field polygon around center
  void _createDemoField() {
    final half = 0.001;
    setState(() {
      _fieldPolygon = [
        LatLng(_center.latitude - half, _center.longitude - half),
        LatLng(_center.latitude - half, _center.longitude + half),
        LatLng(_center.latitude + half, _center.longitude + half),
        LatLng(_center.latitude + half, _center.longitude - half),
      ];
    });
  }

  /// Analyze selected area
  Future<void> _analyzeField() async {
    if (_fieldPolygon.isEmpty) {
      _createDemoField();
    }

    setState(() => _loading = true);

    final lat = _center.latitude;
    final lng = _center.longitude;

    try {
      final result = await _apiService.analyzeField(
        latitude: lat,
        longitude: lng,
      );
      setState(() {
        _analysis = result;
        _generateGrid(result);
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Generate hotspot grid overlay from analysis data
  void _generateGrid(Analysis analysis) {
    if (analysis.hotspotGrid.isEmpty) {
      // Generate synthetic grid if no real data
      _generateSyntheticGrid();
      return;
    }

    final polygons = <Polygon>[];
    for (final cell in analysis.hotspotGrid) {
      final half = 0.0002; // ~20m per cell
      final color = cell.isStressed
          ? const Color(0xFFE74C3C).withValues(alpha: 0.38)
          : const Color(0xFF64B5F6).withValues(alpha: 0.38);

      polygons.add(Polygon(
        points: [
          LatLng(cell.lat - half, cell.lng - half),
          LatLng(cell.lat - half, cell.lng + half),
          LatLng(cell.lat + half, cell.lng + half),
          LatLng(cell.lat + half, cell.lng - half),
        ],
        color: color,
        borderColor: color,
        borderStrokeWidth: 1,
      ));
    }
    setState(() => _gridPolygons = polygons);
  }

  void _generateSyntheticGrid() {
    final polygons = <Polygon>[];
    final half = 0.0009;
    final latStep = half * 2 / 5;
    final lngStep = half * 2 / 5;
    final startLat = _center.latitude - half;
    final startLng = _center.longitude - half;

    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        final ndvi = 0.27 + (i * j * 7 % 58) / 100;
        final isHotspot = ndvi < 0.45;
        final color = isHotspot
            ? const Color(0xFFE74C3C).withValues(alpha: 0.38)
            : const Color(0xFF64B5F6).withValues(alpha: 0.38);

        polygons.add(Polygon(
          points: [
            LatLng(startLat + i * latStep, startLng + j * lngStep),
            LatLng(startLat + i * latStep, startLng + (j + 1) * lngStep),
            LatLng(startLat + (i + 1) * latStep, startLng + (j + 1) * lngStep),
            LatLng(startLat + (i + 1) * latStep, startLng + j * lngStep),
          ],
          color: color,
          borderColor: color,
          borderStrokeWidth: 1,
        ));
      }
    }
    setState(() => _gridPolygons = polygons);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Field Map'),
        actions: [
          // GPS toggle
          IconButton(
            icon: Icon(
              Icons.my_location,
              color: _gpsActive ? const Color(0xFF2E7D32) : const Color(0xFF71717A),
            ),
            onPressed: _centerOnGps,
            tooltip: 'My Location',
          ),
          // Grid toggle
          IconButton(
            icon: Icon(
              Icons.grid_on,
              color: _gridVisible ? const Color(0xFF2E7D32) : const Color(0xFF71717A),
            ),
            onPressed: () => setState(() => _gridVisible = !_gridVisible),
            tooltip: 'Hotspot Grid',
          ),
        ],
      ),
      body: Stack(
        children: [
          // === MAP ===
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onTap: (_, latlng) {
                // Add point to polygon on tap
                setState(() {
                  _fieldPolygon.add(latlng);
                  if (_fieldPolygon.length > 4) {
                    _fieldPolygon = _fieldPolygon.sublist(_fieldPolygon.length - 4);
                  }
                });
              },
            ),
            children: [
              // Tile layer
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.krishidrishti.app',
              ),

              // Field polygon
              if (_fieldPolygon.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _fieldPolygon,
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderColor: const Color(0xFF2E7D32),
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),

              // Hotspot grid
              if (_gridVisible && _gridPolygons.isNotEmpty)
                PolygonLayer(polygons: _gridPolygons),

              // GPS marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 40,
                    height: 40,
                    child: Icon(
                      _gpsActive ? Icons.my_location : Icons.location_on,
                      color: _gpsActive
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFEF4444),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // === BOTTOM CONTROLS ===
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Analysis result card
                if (_analysis != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF27272A)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Crop Health',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF71717A))),
                              const SizedBox(height: 4),
                              Text(
                                '${_analysis!.healthScore}/100',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _analysis!.healthScore >= 80
                                      ? const Color(0xFF4ADE80)
                                      : _analysis!.healthScore >= 65
                                          ? const Color(0xFFFBBF24)
                                          : const Color(0xFFEF4444),
                                ),
                              ),
                              Text(_analysis!.healthStatus,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFFA1A1AA))),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text('NDVI ${(_analysis!.ndvi * 100).toInt()}%',
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF4ADE80))),
                            const SizedBox(height: 4),
                            Text('Moisture ${_analysis!.soilMoisturePct.toInt()}%',
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF60A5FA))),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildControlButton(
                        icon: Icons.touch_app,
                        label: 'Draw Field',
                        onTap: () {
                          setState(() => _fieldPolygon = []);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tap on map to draw field boundary'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildControlButton(
                        icon: Icons.demo,
                        label: 'Demo Field',
                        onTap: _createDemoField,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildAnalyzeButton(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // === LOADING ===
          if (_loading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    SizedBox(height: 16),
                    Text('Analyzing field...',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Fetching Sentinel-2 & weather data',
                        style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFA1A1AA), size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFA1A1AA),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return GestureDetector(
      onTap: _analyzeField,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Analyze',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gpsService.dispose();
    super.dispose();
  }
}
