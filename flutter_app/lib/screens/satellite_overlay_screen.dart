import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/satellite_overlay_service.dart';
import '../models/satellite_scene.dart';

/// Satellite imagery overlay screen - inspired by image-satellite-visualizer
/// Browse satellite scenes, view NDVI overlays, compare historical data
class SatelliteOverlayScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const SatelliteOverlayScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<SatelliteOverlayScreen> createState() => _SatelliteOverlayScreenState();
}

class _SatelliteOverlayScreenState extends State<SatelliteOverlayScreen> with SingleTickerProviderStateMixin {
  final SatelliteOverlayService _satService = SatelliteOverlayService();
  final MapController _mapController = MapController();
  late TabController _tabController;

  List<SatelliteScene> _scenes = [];
  SatelliteScene? _selectedScene;
  Map<String, dynamic>? _comparison;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadScenes();
  }

  Future<void> _loadScenes() async {
    setState(() => _loading = true);
    final lat = widget.initialLat ?? 25.3176;
    final lng = widget.initialLng ?? 82.9739;
    await _satService.loadScenesForLocation(lat, lng);
    if (mounted) {
      setState(() {
        _scenes = _satService.availableScenes;
        _selectedScene = _satService.getLatestClearScene();
        _loading = false;
      });
    }
  }

  void _selectScene(String sceneId) {
    _satService.selectScene(sceneId);
    setState(() {
      _selectedScene = _satService.selectedScene;
    });
  }

  void _compareScenes(String id1, String id2) {
    final result = _satService.compareScenes(id1, id2);
    setState(() => _comparison = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Row(
          children: [Icon(Icons.satellite, color: Color(0xFF2E7D32), size: 20), SizedBox(width: 8), Text('Satellite Imagery')],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2E7D32),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF71717A),
          tabs: const [
            Tab(text: 'Scenes', icon: Icon(Icons.image, size: 18)),
            Tab(text: 'Map View', icon: Icon(Icons.map, size: 18)),
            Tab(text: 'Comparison', icon: Icon(Icons.compare, size: 18)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSceneList(),
                _buildMapView(),
                _buildComparisonTab(),
              ],
            ),
    );
  }

  Widget _buildSceneList() {
    if (_scenes.isEmpty) {
      return const Center(child: Text('No scenes available', style: TextStyle(color: Colors.white38)));
    }

    // Source filter chips
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', null),
                const SizedBox(width: 8),
                _filterChip('Sentinel-2', SatelliteSource.sentinel2),
                const SizedBox(width: 8),
                _filterChip('Landsat 8', SatelliteSource.landsat8),
                const SizedBox(width: 8),
                _filterChip('Landsat 9', SatelliteSource.landsat9),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _scenes.length,
            itemBuilder: (_, i) {
              final scene = _scenes[i];
              final isSelected = _selectedScene?.id == scene.id;
              return GestureDetector(
                onTap: () => _selectScene(scene.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF27272A),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Color(int.parse(scene.sourceColor.replaceAll('#', '0xFF'))).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(scene.source == SatelliteSource.sentinel2 ? 'S2' :
                              scene.source == SatelliteSource.landsat8 ? 'L8' : 'L9',
                              style: TextStyle(
                                color: Color(int.parse(scene.sourceColor.replaceAll('#', '0xFF'))),
                                fontSize: 14, fontWeight: FontWeight.bold,
                              )),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(scene.sourceName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('${scene.acquisitionDate.year}-${scene.acquisitionDate.month.toString().padLeft(2, '0')}-${scene.acquisitionDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${scene.cloudCover.toStringAsFixed(0)}% cloud', style: const TextStyle(
                            color: scene.cloudCover < 20 ? const Color(0xFF4ADE80) :
                                   scene.cloudCover < 50 ? const Color(0xFFFBBF24) :
                                   const Color(0xFFEF4444),
                            fontSize: 11,
                          )),
                          const SizedBox(height: 2),
                          if (scene.ndviMean != null)
                            Text('NDVI ${scene.ndviMean!.toStringAsFixed(2)}',
                                style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, SatelliteSource? source) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _scenes = source != null
              ? _satService.getScenesBySource(source)
              : _satService.availableScenes;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(widget.initialLat ?? 25.3176, widget.initialLng ?? 82.9739),
            initialZoom: 13,
          ),
          children: [
            TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
            // If scene selected, overlay NDVI color grid
            if (_selectedScene != null) ...[
              PolygonLayer(
                polygons: _buildNdviOverlay(_selectedScene!),
              ),
            ],
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(widget.initialLat ?? 25.3176, widget.initialLng ?? 82.9739),
                  width: 40, height: 40,
                  child: const Icon(Icons.satellite_alt, color: Color(0xFF2E7D32), size: 28),
                ),
              ],
            ),
          ],
        ),
        if (_selectedScene != null)
          Positioned(
            left: 12, right: 12, bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_selectedScene!.sourceName} · ${_selectedScene!.acquisitionDate.toString().substring(0, 10)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('NDVI: ${_selectedScene!.ndviMean?.toStringAsFixed(2) ?? '--'} · Cloud: ${_selectedScene!.cloudCover.toStringAsFixed(0)}%',
                            style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
                      ],
                    ),
                  ),
                  // NDVI legend
                  Container(
                    height: 20, width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFA50026),
                          const Color(0xFFF46D43),
                          const Color(0xFFFFD53F),
                          const Color(0xFF90C95B),
                          const Color(0xFF1A964B),
                          const Color(0xFF003C20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<Polygon> _buildNdviOverlay(SatelliteScene scene) {
    if (scene.ndviMean == null) return [];

    final polygons = <Polygon>[];
    final lat = scene.latitude;
    final lng = scene.longitude;
    final half = 0.002;
    final rows = 8;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < rows; j++) {
        final ndvi = (scene.ndviMin ?? 0.1) +
            (((i * rows + j) * 7) % 100 / 100.0) *
            ((scene.ndviMax ?? 0.8) - (scene.ndviMin ?? 0.1));
        final color = NdviColorRamp.colorForNdvi(ndvi);

        polygons.add(Polygon(
          points: [
            LatLng(lat - half + i * (half * 2 / rows), lng - half + j * (half * 2 / rows)),
            LatLng(lat - half + i * (half * 2 / rows), lng - half + (j + 1) * (half * 2 / rows)),
            LatLng(lat - half + (i + 1) * (half * 2 / rows), lng - half + (j + 1) * (half * 2 / rows)),
            LatLng(lat - half + (i + 1) * (half * 2 / rows), lng - half + j * (half * 2 / rows)),
          ],
          color: Color.fromARGB(80, color.r, color.g, color.b),
          borderColor: Colors.transparent,
          borderStrokeWidth: 0,
        ));
      }
    }

    return polygons;
  }

  Widget _buildComparisonTab() {
    if (_scenes.length < 2) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('Need at least 2 scenes for comparison', style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      );
    }

    final scene1 = _scenes.isNotEmpty ? _scenes[0] : null;
    final scene2 = _scenes.length > 1 ? _scenes[1] : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Scene pickers
        Row(
          children: [
            Expanded(child: _scenePicker(scene1, 'Scene 1', (s) => _compareScenes(s.id, scene2?.id ?? ''))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.compare_arrows, color: Color(0xFF71717A)),
            ),
            Expanded(child: _scenePicker(scene2, 'Scene 2', (s) => _compareScenes(scene1?.id ?? '', s.id))),
          ],
        ),

        if (_comparison != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Column(
              children: [
                const Text('NDVI Change', style: TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                const SizedBox(height: 8),
                Text('${_comparison!['changePercent']}%', style: TextStyle(
                  fontSize: 40, fontWeight: FontWeight.bold,
                  color: _comparison!['trend'] == 'Improving'
                      ? const Color(0xFF4ADE80)
                      : _comparison!['trend'] == 'Declining'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFFBBF24),
                )),
                Text('${_comparison!['trend']}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF27272A)),
                _compRow('NDVI Values', '${_comparison!['scene1Ndvi']} → ${_comparison!['scene2Ndvi']}', Colors.white70),
                _compRow('Days Between', '${_comparison!['daysBetween']} days', const Color(0xFF71717A)),
                _compRow('Absolute Change', '${_comparison!['change']}', const Color(0xFF4ADE80)),
                const SizedBox(height: 12),
                _trendBar(_comparison!['changePercent']),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _scenePicker(SatelliteScene? scene, String label, void Function(SatelliteScene) onSelect) {
    return GestureDetector(
      onTap: scene != null ? () => onSelect(scene) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
            const SizedBox(height: 6),
            if (scene != null) ...[
              Text(scene.sourceName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(scene.acquisitionDate.toString().substring(0, 10), style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
              Text('NDVI ${scene.ndviMean?.toStringAsFixed(2) ?? '--'}', style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 11)),
            ] else
              const Text('Select...', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _compRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
          const Spacer(),
          Text(value, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _trendBar(double changePercent) {
    final clamped = changePercent.clamp(-100, 100).toDouble();
    final width = (clamped / 100 * 200).clamp(-200, 200);
    return Column(
      children: [
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            width: 200,
            child: Stack(
              children: [
                Container(color: const Color(0xFF27272A)),
                Align(
                  alignment: width < 0 ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    width: width.abs(),
                    height: 8,
                    color: changePercent >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('% Change', style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
