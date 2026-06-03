import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/farm.dart';
import '../services/storage_service.dart';

/// Shows saved farms list with GPS distance info
class SavedFarmsScreen extends StatefulWidget {
  final AppUser? user;
  final void Function(double lat, double lng)? onFarmSelected;
  const SavedFarmsScreen({super.key, this.user, this.onFarmSelected});

  @override
  State<SavedFarmsScreen> createState() => _SavedFarmsScreenState();
}

class _SavedFarmsScreenState extends State<SavedFarmsScreen> {
  List<Farm> _farms = [];

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  void _loadFarms() {
    setState(() => _farms = StorageService.instance.getSavedFarms());
  }

  void _deleteFarm(String id) async {
    await StorageService.instance.removeFarm(id);
    _loadFarms();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.bookmark, color: Color(0xFF2E7D32), size: 20),
            const SizedBox(width: 8),
            Text('Saved Farms (${_farms.length})'),
          ],
        ),
      ),
      body: _farms.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_outline,
                      size: 64, color: Colors.grey[800]),
                  const SizedBox(height: 16),
                  const Text('No saved farms yet',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Go to Map → Analyze → Save',
                      style: TextStyle(color: Color(0xFF52525B), fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _farms.length,
              itemBuilder: (_, i) => _buildFarmCard(_farms[i]),
            ),
    );
  }

  Widget _buildFarmCard(Farm farm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(farm.name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${farm.latitude.toStringAsFixed(4)}, ${farm.longitude.toStringAsFixed(4)}',
              style: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.favorite, size: 14,
                    color: farm.healthScore >= 80
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFFBBF24)),
                const SizedBox(width: 4),
                Text('${farm.healthScore}/100',
                    style: const TextStyle(
                        color: Color(0xFFA1A1AA), fontSize: 12)),
                const SizedBox(width: 12),
                Icon(Icons.map, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(farm.cropType,
                    style: const TextStyle(
                        color: Color(0xFF52525B), fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.map, color: Color(0xFF2E7D32), size: 20),
              onPressed: () => widget.onFarmSelected
                  ?.call(farm.latitude, farm.longitude),
              tooltip: 'Open on map',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFEF4444), size: 20),
              onPressed: () => _deleteFarm(farm.id),
              tooltip: 'Remove',
            ),
          ],
        ),
        onTap: () => widget.onFarmSelected
            ?.call(farm.latitude, farm.longitude),
      ),
    );
  }
}
