import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/survey_service.dart';
import '../services/gps_service.dart';
import '../models/survey_point.dart';

/// Field Survey Pro screen - inspired by OSMTracker
/// Collects structured survey data with photos, voice notes, and offline sync
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> with SingleTickerProviderStateMixin {
  final SurveyService _surveyService = SurveyService();
  final GpsService _gpsService = GpsService();
  late TabController _tabController;

  List<SurveyPoint> _points = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    _currentPosition = await _gpsService.getCurrentLocation();
    final points = await _surveyService.getSurveyPoints();
    if (mounted) setState(() => _points = points);
  }

  void _startNewSurvey(SurveyType type) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _SurveyFormScreen(
        type: type,
        position: _currentPosition,
        onSaved: () => _loadData(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Row(
          children: [Icon(Icons.assignment, color: Color(0xFF2E7D32), size: 20), SizedBox(width: 8), Text('Field Survey')],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2E7D32),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF71717A),
          tabs: const [
            Tab(text: 'New Survey', icon: Icon(Icons.add, size: 18)),
            Tab(text: 'History', icon: Icon(Icons.list, size: 18)),
            Tab(text: 'Stats', icon: Icon(Icons.bar_chart, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewSurvey(),
          _buildHistory(),
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildNewSurvey() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: SurveyService.allTemplates.map((template) => GestureDetector(
        onTap: () => _startNewSurvey(template.type),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),                        child: Center(child: Text(surveyTypeIcon(template.type), style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('${template.fields.length} fields', style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF71717A), size: 14),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildHistory() {
    if (_points.isEmpty) {
      return const Center(child: Text('No survey data yet', style: TextStyle(color: Colors.white38)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _points.length,
      itemBuilder: (_, i) {
        final p = _points[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: Row(
            children: [
              Text(p.typeIcon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name ?? p.typeName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)} · ${_timeAgo(p.timestamp)}',
                        style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                  ],
                ),
              ),
              if (!p.synced)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFBBF24).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Offline', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 9)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _surveyService.getStats(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final s = snap.data!;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _statCard('Total Surveys', '${s['total']}', Icons.assignment),
              const SizedBox(height: 8),
              _statCard('Pest Checks', '${s['pestChecks']}', Icons.bug_report),
              _statCard('Soil Samples', '${s['soilSamples']}', Icons.science),
              _statCard('Crop Conditions', '${s['cropConditions']}', Icons.agriculture),
              const SizedBox(height: 12),
              _statCard('Synced', '${s['synced']} / ${s['total']}', Icons.cloud_done),
              _statCard('This Week', '${s['recentWeek']}', Icons.calendar_today),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF27272A))),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

/// Survey form screen for structured data collection
class _SurveyFormScreen extends StatefulWidget {
  final SurveyType type;
  final Position? position;
  final VoidCallback onSaved;

  const _SurveyFormScreen({required this.type, this.position, required this.onSaved});

  @override
  State<_SurveyFormScreen> createState() => _SurveyFormScreenState();
}

class _SurveyFormScreenState extends State<_SurveyFormScreen> {
  final _formData = <String, dynamic>{};
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final template = SurveyService.getTemplate(widget.type);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(                  title: Text('${surveyTypeIcon(template.type)} ${template.name}'),
        actions: [
          _saving
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveSurvey,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Point Name (optional)',
                labelStyle: TextStyle(color: Color(0xFF71717A)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF27272A))),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: Color(0xFF71717A)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF27272A))),
              ),
            ),
            const SizedBox(height: 20),
            ...template.fields.map((field) => _buildFormField(field)),
            if (widget.position != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 16),
                    const SizedBox(width: 8),
                    Text('${widget.position!.latitude.toStringAsFixed(5)}, ${widget.position!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(SurveyFormField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${field.label}${field.required ? ' *' : ''}',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: field.required ? FontWeight.w600 : FontWeight.normal)),
          const SizedBox(height: 8),
          switch (field.fieldType) {
            SurveyFieldType.text => TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF27272A))),
                ),
                onChanged: (v) => _formData[field.key] = v,
              ),
            SurveyFieldType.number => TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF27272A))),
                ),
                onChanged: (v) => _formData[field.key] = double.tryParse(v),
              ),
            SurveyFieldType.multilineText => TextField(
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF27272A))),
                ),
                onChanged: (v) => _formData[field.key] = v,
              ),
            SurveyFieldType.dropdown => DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF27272A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF27272A))),
                ),
                items: field.options?.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: (v) => _formData[field.key] = v,
              ),
            SurveyFieldType.rating => Row(
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(
                    i < ((_formData[field.key] ?? 0) as int) ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFBBF24),
                  ),
                  onPressed: () => setState(() => _formData[field.key] = i + 1),
                )),
              ),
            SurveyFieldType.yesNo => Row(
                children: ['Yes', 'No'].map((v) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(v, style: TextStyle(color: _formData[field.key] == v ? Colors.white : Colors.white70, fontSize: 12)),
                    selected: _formData[field.key] == v,
                    selectedColor: const Color(0xFF2E7D32),
                    backgroundColor: const Color(0xFF27272A),
                    onSelected: (_) => setState(() => _formData[field.key] = v),
                  ),
                )).toList(),
              ),
            SurveyFieldType.photo => ElevatedButton.icon(
                onPressed: () => debugPrint('📸 Take photo'),
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27272A)),
              ),
            SurveyFieldType.voiceNote => ElevatedButton.icon(
                onPressed: () => debugPrint('🎤 Record voice'),
                icon: const Icon(Icons.mic, size: 16),
                label: const Text('Record Voice Note'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27272A)),
              ),
          },
        ],
      ),
    );
  }

  Future<void> _saveSurvey() async {
    if (widget.position == null) return;
    setState(() => _saving = true);

    final point = SurveyPoint(
      id: 'survey_${DateTime.now().millisecondsSinceEpoch}',
      type: widget.type,
      latitude: widget.position!.latitude,
      longitude: widget.position!.longitude,
      altitude: widget.position!.altitude,
      name: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : null,
      description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
      formData: _formData,
    );

    await SurveyService().saveSurveyPoint(point);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
}
