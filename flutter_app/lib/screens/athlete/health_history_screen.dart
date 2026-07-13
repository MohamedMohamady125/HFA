import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          FadeSlideIn(
            child: HeroHeader(
              title: l.translate('health_history'),
              subtitle: l.translate('health_history_desc'),
              leading: HeaderIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
            ),
          ),
          Expanded(
            child: loading
                ? const ShimmerList(count: 3)
                : records.isEmpty
                    ? EmptyState(
                        icon: Icons.medical_information_outlined,
                        title: l.translate('no_health_records'),
                        message: l.translate('tap_add_record'),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetch,
                        color: AppColors.accent,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                          itemCount: records.length,
                          itemBuilder: (_, i) {
                            final r = records[i];
                            final files = r['files'] as List? ?? [];
                            final date = r['created_at'] != null ? DateTime.tryParse(r['created_at']) : null;
                            final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '';

                            return FadeSlideIn(delay: i * 50, child: AppCard(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  const IconBadge(icon: Icons.medical_information_rounded, color: AppColors.error),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(r['title'] ?? '', style: AppTypography.titleMedium),
                                    const SizedBox(height: 2),
                                    Text(dateStr, style: AppTypography.caption),
                                  ])),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                    onPressed: () => _deleteRecord(r['id']),
                                  ),
                                ]),
                                if (r['notes'] != null && r['notes'].toString().isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(AppRadius.sm)),
                                    child: Text(r['notes'], style: AppTypography.bodyMedium),
                                  ),
                                ],
                                if (files.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  SizedBox(
                                    height: 80,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: files.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                                      itemBuilder: (_, fi) {
                                        final file = files[fi];
                                        final bytes = base64Decode(file['file_data']);
                                        return ScaleOnTap(
                                          onTap: () => _showFullImage(bytes, file['file_name'] ?? ''),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(AppRadius.sm),
                                            child: Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ]),
                            ));
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(Uint8List bytes, String name) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
          const SizedBox(height: AppSpacing.md),
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
      body: Column(
        children: [
          FadeSlideIn(
            child: HeroHeader(
              title: l.translate('new_health_record'),
              leading: HeaderIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.translate('record_name'), style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(hintText: l.translate('record_name_hint')),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(l.translate('notes_label'), style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(hintText: l.translate('notes_hint')),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(l.translate('attachments'), style: AppTypography.label),
                const SizedBox(height: AppSpacing.xs),
                Text(l.translate('max_2_photos'), style: AppTypography.caption),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  ..._files.map((f) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
                    child: Stack(clipBehavior: Clip.none, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.file(File(f.path), width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      PositionedDirectional(top: -6, end: -6, child: GestureDetector(
                        onTap: () => setState(() => _files.remove(f)),
                        child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 14)),
                      )),
                    ]),
                  )),
                  if (_files.length < 2)
                    ScaleOnTap(
                      onTap: _pickImage,
                      child: Container(width: 80, height: 80,
                        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.3), style: BorderStyle.solid)),
                        child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textTertiary, size: 28),
                      ),
                    ),
                ]),
                const SizedBox(height: AppSpacing.xxxl),
                PrimaryButton(
                  label: l.translate('save_record'),
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _titleCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }
}
