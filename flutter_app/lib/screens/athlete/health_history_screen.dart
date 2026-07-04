import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});
  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  List<dynamic> records = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    try {
      final res = await ApiService().get('/athlete/health-records');
      records = res.data is List ? res.data : [];
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> _deleteRecord(int id) async {
    final l = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.translate('delete'), style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(l.translate('delete_health_record_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.translate('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.translate('delete')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService().delete('/athlete/health-records/$id');
      records.removeWhere((r) => r['id'] == id);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _openCreateDialog() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _CreateHealthRecordScreen(onCreated: () {
      _fetch();
    })));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.translate('health_history'))),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: loading
          ? const ShimmerList(count: 3)
          : records.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.medical_information_outlined, size: 56, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(l.translate('no_health_records'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(l.translate('tap_add_record'), style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                ]))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                    itemCount: records.length,
                    itemBuilder: (_, i) {
                      final r = records[i];
                      final files = r['files'] as List? ?? [];
                      final date = r['created_at'] != null ? DateTime.tryParse(r['created_at']) : null;
                      final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '';

                      return FadeSlideIn(delay: i * 50, child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(width: 40, height: 40,
                              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.medical_information_rounded, color: AppColors.error, size: 20)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                            ])),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                              onPressed: () => _deleteRecord(r['id']),
                            ),
                          ]),
                          if (r['notes'] != null && r['notes'].toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(r['notes'], style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                          ],
                          if (files.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 80,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: files.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (_, fi) {
                                  final file = files[fi];
                                  final bytes = base64Decode(file['file_data']);
                                  return GestureDetector(
                                    onTap: () => _showFullImage(bytes, file['file_name'] ?? ''),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ])),
                      ));
                    },
                  ),
                ),
    );
  }

  void _showFullImage(List<int> bytes, String name) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(bytes as dynamic, fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// CREATE HEALTH RECORD
// ═══════════════════════════════════════════════════════
class _CreateHealthRecordScreen extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateHealthRecordScreen({required this.onCreated});
  @override
  State<_CreateHealthRecordScreen> createState() => _CreateHealthRecordScreenState();
}

class _CreateHealthRecordScreenState extends State<_CreateHealthRecordScreen> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<XFile> _files = [];
  bool _saving = false;

  Future<void> _pickImage() async {
    if (_files.length >= 2) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 1200);
    if (picked != null) setState(() => _files.add(picked));
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.translate('enter_record_title')), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _saving = true);
    try {
      final filesData = <Map<String, String>>[];
      for (final f in _files) {
        final bytes = await File(f.path).readAsBytes();
        filesData.add({
          'file_name': f.name,
          'file_data': base64Encode(bytes),
        });
      }

      await ApiService().post('/athlete/health-records', data: {
        'title': _titleCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'files': filesData.isEmpty ? null : filesData,
      });

      widget.onCreated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.translate('record_created')), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.translate('save_failed')), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.translate('new_health_record'))),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.translate('record_name'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(hintText: l.translate('record_name_hint')),
          ),
          const SizedBox(height: 20),
          Text(l.translate('notes_label'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            decoration: InputDecoration(hintText: l.translate('notes_hint')),
          ),
          const SizedBox(height: 20),
          Text(l.translate('attachments'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(l.translate('max_2_photos'), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          const SizedBox(height: 10),
          Row(children: [
            ..._files.map((f) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(clipBehavior: Clip.none, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(f.path), width: 80, height: 80, fit: BoxFit.cover),
                ),
                Positioned(top: -6, right: -6, child: GestureDetector(
                  onTap: () => setState(() => _files.remove(f)),
                  child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 14)),
                )),
              ]),
            )),
            if (_files.length < 2)
              GestureDetector(
                onTap: _pickImage,
                child: Container(width: 80, height: 80,
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.3), style: BorderStyle.solid)),
                  child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textTertiary, size: 28),
                ),
              ),
          ]),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(l.translate('save_record')),
          )),
        ]),
      ),
    );
  }

  @override
  void dispose() { _titleCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }
}
