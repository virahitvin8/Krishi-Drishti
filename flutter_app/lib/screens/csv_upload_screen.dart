import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

/// Screen for uploading CSV files with batch field analysis
class CsvUploadScreen extends StatefulWidget {
  const CsvUploadScreen({super.key});

  @override
  State<CsvUploadScreen> createState() => _CsvUploadScreenState();
}

class _CsvUploadScreenState extends State<CsvUploadScreen> {
  File? _selectedFile;
  String? _fileName;
  bool _uploading = false;
  Map<String, dynamic>? _result;
  String? _previewContent;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final sizeMB = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(1);

      if (file.lengthSync() > 50 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File too large. Max 50 MB')),
          );
        }
        return;
      }

      // Preview first few lines cross-platform
      try {
        final bytes = await file.readAsBytes();
        final content = utf8.decode(bytes);
        final lines = content.split('\n').take(5).join('\n');

        setState(() {
          _selectedFile = file;
          _fileName = '${result.files.first.name} ($sizeMB MB)';
          _previewContent = lines;
          _result = null;
        });
      } catch (_) {
        setState(() {
          _selectedFile = file;
          _fileName = result.files.first.name;
          _previewContent = null;
        });
      }
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() => _uploading = true);

    try {
      final response = await ApiService().uploadCsv(_selectedFile!);
      setState(() => _result = response);
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(title: const Text('Upload CSV')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
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
                  const Text('CSV Format',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Color(0xFF4ADE80))),
                  const SizedBox(height: 8),
                  const Text('Required columns: latitude, longitude',
                      style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF09090B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'latitude, longitude, field_id, crop_type, area_hectares\n'
                      '25.3176, 82.9739, F1, wheat, 2.5\n'
                      '25.3200, 82.9700, F2, rice, 3.0',
                      style: TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Max file size: 50 MB',
                      style: TextStyle(color: Color(0xFF52525B), fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // File picker
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile != null
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF27272A),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.check_circle
                          : Icons.upload_file,
                      size: 40,
                      color: _selectedFile != null
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF52525B),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile != null ? 'File selected' : 'Tap to select CSV',
                      style: TextStyle(
                        color: _selectedFile != null
                            ? Colors.white
                            : const Color(0xFF71717A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_fileName != null) ...[
                      const SizedBox(height: 4),
                      Text(_fileName!,
                          style: const TextStyle(
                              color: Color(0xFF52525B), fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),

            // Preview
            if (_previewContent != null) ...[
              const SizedBox(height: 16),
              const Text('Preview',
                  style: TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: Text(_previewContent!,
                    style: const TextStyle(
                        color: Color(0xFFA1A1AA),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        height: 1.5)),
              ),
            ],

            const SizedBox(height: 24),

            // Upload button
            if (_selectedFile != null)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _uploadFile,
                  icon: _uploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_uploading ? 'Uploading...' : 'Upload & Analyze',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF1a5e1e),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

            // Results
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final success = _result!['success'] == true ||
        _result!['processed'] != null;
    final processed = _result!['processed'] ?? 0;
    final failed = _result!['failed'] ?? 0;
    final errors = _result!['errors'] as List? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: success
            ? const Color(0xFF052E16)
            : const Color(0xFF450A0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: success
              ? const Color(0xFF166534)
              : const Color(0xFF7F1D1D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFFEF4444),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                success ? 'Upload Complete' : 'Upload Failed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: success
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFEF4444),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Processed: $processed fields',
              style: const TextStyle(color: Color(0xFFD4D4D8))),
          Text('Failed: $failed',
              style: const TextStyle(color: Color(0xFFA1A1AA))),
          if (_result!['batch_id'] != null)
            Text('Batch: ${_result!['batch_id']}',
                style: const TextStyle(color: Color(0xFF52525B), fontSize: 12)),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Errors:',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ...errors.take(3).map((e) => Text('• $e',
                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11))),
          ],
        ],
      ),
    );
  }
}

/// Simple line splitter for preview
class LineSplitter extends Converter<String, List<String>> {
  const LineSplitter();
  @override
  List<String> convert(String input) => input.split('\n');
}
