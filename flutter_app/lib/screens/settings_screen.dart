import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/storage_service.dart';

/// Settings screen with profile, preferences, language, and account management
class SettingsScreen extends StatefulWidget {
  final AppUser? user;
  final VoidCallback? onLogout;
  const SettingsScreen({super.key, this.user, this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  bool _autoRefresh = true;
  bool _notifications = true;
  bool _saveHistory = true;
  String _language = 'en';
  String _state = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user?.displayName ?? '',
    );
    _loadPrefs();
  }

  void _loadPrefs() {
    final prefs = StorageService.instance.getPreferences();
    setState(() {
      _autoRefresh = prefs['autoRefresh'] ?? true;
      _notifications = prefs['notifications'] ?? true;
      _saveHistory = prefs['saveHistory'] ?? true;
    });
  }

  void _saveSettings() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    if (widget.user != null) {
      widget.user!.language = _language;
      widget.user!.state = _state;
      await StorageService.instance.saveUser(widget.user!);
    }

    await StorageService.instance.savePreferences({
      'autoRefresh': _autoRefresh,
      'notifications': _notifications,
      'saveHistory': _saveHistory,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved ✅'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Profile ===
            _buildSection(
              title: 'Profile',
              icon: Icons.person,
              color: const Color(0xFF4ADE80),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Display Name', Icons.person_outline),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _language,
                    dropdownColor: const Color(0xFF18181B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Language', Icons.language),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                      DropdownMenuItem(value: 'te', child: Text('తెలుగు')),
                    ],
                    onChanged: (v) => setState(() => _language = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _state.isEmpty ? null : _state,
                    dropdownColor: const Color(0xFF18181B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('State', Icons.location_city),
                    items: [
                      'Uttar Pradesh', 'Punjab', 'Maharashtra', 'Karnataka',
                      'Telangana', 'Gujarat', 'Rajasthan', 'Andhra Pradesh',
                      'Tamil Nadu', 'Madhya Pradesh', 'Bihar', 'West Bengal',
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _state = v ?? ''),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // === Data Preferences ===
            _buildSection(
              title: 'Data Preferences',
              icon: Icons.satellite_alt,
              color: const Color(0xFF60A5FA),
              child: Column(
                children: [
                  _buildSwitch('Auto-refresh satellite data every 7 days',
                      _autoRefresh, (v) => setState(() => _autoRefresh = v)),
                  _buildSwitch('Notify when new data available',
                      _notifications, (v) => setState(() => _notifications = v)),
                  _buildSwitch('Save analysis history locally',
                      _saveHistory, (v) => setState(() => _saveHistory = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // === Account ===
            _buildSection(
              title: 'Account',
              icon: Icons.lock,
              color: const Color(0xFFFBBF24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.user != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Logged in as ${widget.user!.displayName}',
                        style: const TextStyle(color: Color(0xFFA1A1AA)),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                      label: const Text('Logout',
                          style: TextStyle(color: Color(0xFFEF4444))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7F1D1D)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // === Save Button ===
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Save Settings',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('App v4.1 • Jai Kisan 🌾',
                  style: TextStyle(color: Color(0xFF52525B), fontSize: 12)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: Color(0xFF52525B), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF71717A), size: 20),
      filled: true,
      fillColor: const Color(0xFF27272A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFFD4D4D8), fontSize: 14)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }
}
