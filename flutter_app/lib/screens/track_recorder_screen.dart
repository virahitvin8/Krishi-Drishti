import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/track_service.dart';
import '../models/track.dart';
import '../services/storage_service.dart';

/// GPS Track Recorder Screen — inspired by OSMTracker and GPSLogger
/// Features: start/stop/pause recording, waypoints, configurable logging, saved tracks
class TrackRecorderScreen extends StatefulWidget {
  const TrackRecorderScreen({super.key});

  @override
  State<TrackRecorderScreen> createState() => _TrackRecorderScreenState();
}

class _TrackRecorderScreenState extends State<TrackRecorderScreen>
    with SingleTickerProviderStateMixin {
  final TrackService _trackService = TrackService();
  late TabController _tabController;
  StreamSubscription? _trackSub;
  GpsTrack? _currentTrack;
  Position? _lastPosition;
  List<Map<String, dynamic>> _savedTracks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _trackService.loadSettings();
    _trackSub = _trackService.trackStream.listen((track) {
      if (mounted) setState(() => _currentTrack = track);
    });
    _trackService.positionStream.listen((pos) {
      if (mounted) setState(() => _lastPosition = pos);
    });
    _loadSavedTracks();
  }

  @override
  void dispose() {
    _trackSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedTracks() async {
    final tracks = await _trackService.getSavedTracks();
    if (mounted) setState(() => _savedTracks = tracks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.route, color: Color(0xFF2E7D32), size: 20),
            const SizedBox(width: 8),
            const Text('Track Recorder'),
            if (_trackService.isRecording)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444), shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('REC', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2E7D32),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF71717A),
          tabs: const [
            Tab(text: 'Recorder', icon: Icon(Icons.fiber_manual_record, size: 16)),
            Tab(text: 'Saved Tracks', icon: Icon(Icons.folder_outlined, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecorderTab(),
          _buildSavedTracksTab(),
        ],
      ),
    );
  }

  Widget _buildRecorderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Recording controls card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Column(
              children: [
                // Status indicator
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _trackService.isRecording
                        ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                        : const Color(0xFF2E7D32).withValues(alpha: 0.15),
                    border: Border.all(
                      color: _trackService.isRecording
                          ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                          : const Color(0xFF2E7D32).withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    _trackService.isRecording ? Icons.fiber_manual_record : Icons.stop_circle_outlined,
                    color: _trackService.isRecording ? const Color(0xFFEF4444) : const Color(0xFF2E7D32),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),

                // Track name
                if (_currentTrack != null) ...[
                  Text(_currentTrack!.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                ],

                // Stats
                Row(
                  children: [
                    _statItem('${_currentTrack?.pointCount ?? 0}', 'Points', Icons.gps_fixed),
                    _statItem('${(_currentTrack?.totalDistanceKm ?? 0).toStringAsFixed(2)}', 'km', Icons.straighten),
                    _statItem('${_currentTrack?.waypoints.length ?? 0}', 'Waypoints', Icons.flag),
                  ],
                ),

                const SizedBox(height: 24),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_trackService.isRecording)
                      _controlButton(
                        icon: Icons.fiber_manual_record,
                        label: 'Start',
                        color: const Color(0xFFEF4444),
                        onTap: () => _trackService.startRecording(),
                      )
                    else ...[
                      _controlButton(
                        icon: _currentTrack?.status == TrackStatus.paused
                            ? Icons.play_arrow : Icons.pause,
                        label: _currentTrack?.status == TrackStatus.paused ? 'Resume' : 'Pause',
                        color: const Color(0xFFFBBF24),
                        onTap: () {
                          if (_currentTrack?.status == TrackStatus.paused) {
                            _trackService.resumeRecording();
                          } else {
                            _trackService.pauseRecording();
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      _controlButton(
                        icon: Icons.stop,
                        label: 'Stop',
                        color: const Color(0xFFEF4444),
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF18181B),
                              title: const Text('Stop Recording?', style: TextStyle(color: Colors.white)),
                              content: const Text('${_currentTrack?.pointCount ?? 0} points recorded.',
                                  style: TextStyle(color: Color(0xFFA1A1AA))),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                    child: const Text('Stop')),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await _trackService.stopRecording();
                            _loadSavedTracks();
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Waypoint button (quick add while recording)
          if (_trackService.isRecording && _lastPosition != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () => _showAddWaypointDialog(),
                icon: const Icon(Icons.flag),
                label: const Text('Add Waypoint'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

          // Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Logging Settings',
                    style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildSettingSlider(
                  'Interval',
                  '${_trackService.getStats()['log_interval']}s',
                  1, 30, (_trackService.getStats()['log_interval'] as num).toDouble(),
                  (v) => _trackService.saveSettings(intervalSeconds: v.toInt()),
                ),
                _buildSettingSlider(
                  'Min Distance',
                  '${_trackService.getStats()['accuracy_filter']}m',
                  5, 50, (_trackService.getStats()['accuracy_filter'] as num).toDouble(),
                  (v) => _trackService.saveSettings(accuracyFilter: v.toInt()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSavedTracksTab() {
    if (_savedTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route, size: 64, color: Colors.grey[800]),
            const SizedBox(height: 16),
            const Text('No saved tracks',
                style: TextStyle(color: Color(0xFF71717A), fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Record a field visit to see it here',
                style: TextStyle(color: Color(0xFF52525B), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedTracks.length,
      itemBuilder: (_, i) => _buildTrackCard(_savedTracks[i]),
    );
  }

  Widget _buildTrackCard(Map<String, dynamic> track) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(track['name'] ?? 'Track',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${track['total_points'] ?? 0} points • ${track['distance_km'] ?? '0'} km',
                style: const TextStyle(color: Color(0xFF71717A), fontSize: 13)),
            Text('${track['waypoint_count'] ?? 0} waypoints • ${track['duration_min'] ?? '0'} min',
                style: const TextStyle(color: Color(0xFF52525B), fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF71717A)),
          onSelected: (action) async {
            if (action == 'delete') {
              await _trackService.deleteTrack(track['id']);
              _loadSavedTracks();
            } else if (action == 'export') {
              final gpx = await _trackService.getTrackGpx(track['id']);
                if (gpx != null && mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF18181B),
                      title: const Text('GPX Export', style: TextStyle(color: Colors.white)),
                      content: Text('GPX data ready (${gpx.length} bytes)',
                          style: const TextStyle(color: Color(0xFFA1A1AA))),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context),
                            child: const Text('Close')),
                      ],
                    ),
                  );
                }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'export', child: Text('Export GPX')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Color(0xFFEF4444)))),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddWaypointDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Add Waypoint', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Name (e.g., "Irrigation point")',
                hintStyle: TextStyle(color: Color(0xFF52525B)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF27272A))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Notes (optional)',
                hintStyle: TextStyle(color: Color(0xFF52525B)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF27272A))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_lastPosition != null) {
                _trackService.addWaypoint(
                  latitude: _lastPosition!.latitude,
                  longitude: _lastPosition!.longitude,
                  name: nameController.text.isEmpty ? null : nameController.text,
                  description: descController.text.isEmpty ? null : descController.text,
                  category: 'observation',
                );
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSlider(
    String label, String value, double min, double max, double current, ValueChanged<double> onChange,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13))),
          Expanded(
            child: Slider(
              value: current.clamp(min, max),
              min: min, max: max,
              activeColor: const Color(0xFF2E7D32),
              inactiveColor: const Color(0xFF27272A),
              divisions: (max - min).toInt(),
              label: value,
              onChanged: onChange,
            ),
          ),
          SizedBox(width: 40, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2E7D32), size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon, required String label,
    required Color color, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
