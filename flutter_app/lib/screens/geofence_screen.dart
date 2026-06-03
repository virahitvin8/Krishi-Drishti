import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../services/geofence_service.dart';
import '../services/gps_service.dart';
import '../models/geofence.dart';

/// Geofence management screen - inspired by GPSTest
/// Create, edit, delete geofences around fields with real-time monitoring
class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({super.key});

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> with SingleTickerProviderStateMixin {
  final GeofenceService _geofenceService = GeofenceService();
  final GpsService _gpsService = GpsService();
  final MapController _mapController = MapController();
  late TabController _tabController;

  List<Geofence> _fences = [];
  List<GeofenceEvent> _events = [];
  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await _geofenceService.loadFences();
    if (mounted) {
      setState(() => _fences = _geofenceService.fences);
    }
    _eventSub = _geofenceService.eventStream.listen((event) {
      if (mounted) {
        setState(() => _events.insert(0, event));
      }
    });
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController(text: 'Field ${_fences.length + 1}');
    final radiusCtrl = TextEditingController(text: '100');
    var selectedType = GeofenceType.circular;
    var selectedActions = <GeofenceAction>{GeofenceAction.notify};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          title: const Text('Create Geofence', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Fence Name',
                    labelStyle: TextStyle(color: Color(0xFF71717A)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF27272A))),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GeofenceType>(
                  value: selectedType,
                  dropdownColor: const Color(0xFF27272A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Fence Type',
                    labelStyle: TextStyle(color: Color(0xFF71717A)),
                  ),
                  items: const [
                    DropdownMenuItem(value: GeofenceType.circular, child: Text('Circular (Radius)')),
                    DropdownMenuItem(value: GeofenceType.polygonal, child: Text('Polygonal (Custom)')),
                  ],
                  onChanged: (v) => setDlgState(() => selectedType = v!),
                ),
                if (selectedType == GeofenceType.circular) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: radiusCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Radius (meters)',
                      labelStyle: TextStyle(color: Color(0xFF71717A)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF27272A))),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Actions on trigger:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ...[
                  GeofenceAction.notify,
                  GeofenceAction.startRecording,
                  GeofenceAction.stopRecording,
                  GeofenceAction.takePhoto,
                  GeofenceAction.sendAlert,
                ].map((action) => CheckboxListTile(
                  dense: true,
                  title: Text(
                    action.name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  value: selectedActions.contains(action),
                  onChanged: (v) => setDlgState(() {
                    if (v == true) selectedActions.add(action);
                    else selectedActions.remove(action);
                  }),
                  activeColor: const Color(0xFF2E7D32),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              onPressed: () async {
                final pos = await _gpsService.getCurrentLocation();
                if (pos == null) return;

                final fence = Geofence(
                  id: 'fence_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text,
                  type: selectedType,
                  latitude: pos.latitude,
                  longitude: pos.longitude,
                  radiusMeters: double.tryParse(radiusCtrl.text) ?? 100,
                  actions: selectedActions.toList(),
                );
                await _geofenceService.addFence(fence);
                Navigator.pop(ctx);
                setState(() => _fences = _geofenceService.fences);
              },
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteFence(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Delete Geofence?', style: TextStyle(color: Colors.white)),
        content: const Text('This will remove the fence and stop monitoring this area.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _geofenceService.removeFence(id);
              Navigator.pop(ctx);
              setState(() => _fences = _geofenceService.fences);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.fence, color: Color(0xFF2E7D32), size: 20),
            SizedBox(width: 8),
            Text('Geofencing'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2E7D32),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF71717A),
          tabs: const [
            Tab(text: 'Fences', icon: Icon(Icons.fence, size: 18)),
            Tab(text: 'Map', icon: Icon(Icons.map, size: 18)),
            Tab(text: 'Events', icon: Icon(Icons.history, size: 18)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showCreateDialog),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFenceList(),
          _buildMapView(),
          _buildEventLog(),
        ],
      ),
    );
  }

  Widget _buildFenceList() {
    if (_fences.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fence, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('No geofences yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Create a fence to get notified\nwhen entering or leaving a field', style: TextStyle(color: Colors.white24, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Geofence', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _fences.length,
      itemBuilder: (_, i) {
        final fence = _fences[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: fence.enabled ? const Color(0xFF2E7D32).withValues(alpha: 0.3) : const Color(0xFF27272A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    fence.type == GeofenceType.circular ? Icons.circle_outlined : Icons.hexagon_outlined,
                    color: fence.enabled ? const Color(0xFF4ADE80) : const Color(0xFF71717A),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(fence.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                  Switch(
                    value: fence.enabled,
                    activeColor: const Color(0xFF2E7D32),
                    onChanged: (v) async {
                      final updated = Geofence(
                        id: fence.id, name: fence.name, type: fence.type,
                        latitude: fence.latitude, longitude: fence.longitude,
                        radiusMeters: fence.radiusMeters, enabled: v,
                        actions: fence.actions,
                      );
                      await _geofenceService.updateFence(updated);
                      setState(() => _fences = _geofenceService.fences);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                    onPressed: () => _deleteFence(fence.id),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (fence.type == GeofenceType.circular)
                Text('📍 ${fence.latitude?.toStringAsFixed(4)}, ${fence.longitude?.toStringAsFixed(4)} · ${fence.radiusMeters?.toInt()}m radius',
                    style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: fence.actions.map((a) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(a.name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}'),
                      style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 10)),
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(25.3176, 82.9739),
        initialZoom: 14,
      ),
      children: [
        TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
        PolygonLayer(
          polygons: _fences.where((f) => f.enabled && f.type == GeofenceType.circular && f.latitude != null).map((f) => _buildCirclePolygon(f)).toList(),
        ),
        MarkerLayer(
          markers: _fences.where((f) => f.enabled && f.latitude != null).map((f) => Marker(
            point: LatLng(f.latitude!, f.longitude!),
            width: 30, height: 30,
            child: const Icon(Icons.fence, color: Color(0xFF4ADE80), size: 24),
          )).toList(),
        ),
      ],
    );
  }

  Polygon _buildCirclePolygon(Geofence fence) {
    const segments = 32;
    final points = List.generate(segments, (i) {
      final angle = (i * 360 / segments) * 3.14159 / 180;
      final dlat = (fence.radiusMeters! / 111320) * angle.cos();
      final dlng = (fence.radiusMeters! / (111320 * (fence.latitude! * 3.14159 / 180).cos())) * angle.sin();
      return LatLng(fence.latitude! + dlat, fence.longitude! + dlng);
    });
    return Polygon(
      points: points,
      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
      borderColor: const Color(0xFF4ADE80),
      borderStrokeWidth: 3,
    );
  }

  Widget _buildEventLog() {
    if (_events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No events yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
            SizedBox(height: 8),
            Text('Events appear when you enter or leave\n a geofenced area', style: TextStyle(color: Colors.white24, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      itemBuilder: (_, i) {
        final event = _events[i];
        final isEnter = event.transition == GeofenceTransition.enter;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnter ? const Color(0xFF2E7D32).withValues(alpha: 0.3) : const Color(0xFFEF4444).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(isEnter ? Icons.login : Icons.logout, color: isEnter ? const Color(0xFF4ADE80) : const Color(0xFFEF4444), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('${isEnter ? 'Entered' : 'Left'}: ${event.geofenceName}',
                  style: const TextStyle(color: Colors.white, fontSize: 13))),
              Text('${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventSub?.cancel();
    super.dispose();
  }
}
