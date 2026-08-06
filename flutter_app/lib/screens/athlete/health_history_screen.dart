import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../services/offline/offline_repository.dart';
import '../../services/offline/connectivity_service.dart';
import '../../services/refresh_bus.dart';
import '../../widgets/app_feedback.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});
  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> with LiveRefreshMixin {
  List<dynamic> records = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    // Instant cache read — no spinner if we already have data
    final cached = OfflineRepository.getCached('/athlete/health-records');
    if (cached is List) {
      records = cached;
      loading = false;
    }
    _fetch();
  }

  @override
  void onLiveRefresh() { _fetch(); }

  Future<void> _fetch() async {
    final data = await OfflineRepository.getHealthRecords(onFresh: (fresh) {
      if (mounted && fresh is List) setState(() => records = fresh);
    });
    if (mounted) {
      setState(() {
        records = data;
        loading = false;
      });
    }
  }

  Future<void> _deleteRecord(int id) async {
    final l = AppLocalizations.of(context);
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        decoration: const BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
          ),
          const SizedBox(height: 16),
          Text(l.translate('delete'), style: AppTypography.titleLarge.copyWith(color: AppColors.error)),
          const SizedBox(height: 8),
          Text(l.translate('delete_health_record_confirm'), style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: AppColors.divider)),
              child: Text(l.translate('cancel'), style: TextStyle(color: AppColors.textSecondary)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
              child: Text(l.translate('delete'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )),
          ]),
        ]),
      ),
    );
    if (confirm != true || !mounted) return;
    HapticFeedback.mediumImpact();
    // Optimistic — remove from the list immediately
    setState(() => records.removeWhere((r) => r['id'] == id));
    try {
      final result = await OfflineRepository.deleteHealthRecord(id);
      if (mounted) {
        AppFeedback.showWriteResult(context, result,
            successMessage: l.translate('record_deleted'));
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
        _fetch(); // restore the record on real server error
      }
    }
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
                    ? (!ConnectivityService.isOnline
                        ? EmptyState(
                            icon: Icons.cloud_off_rounded,
                            title: l.translate('no_connection'),
                            message: l.translate('no_connection_data'),
                          )
                        : EmptyState(
                            icon: Icons.medical_information_outlined,
                            title: l.translate('no_health_records'),
                            message: l.translate('tap_add_record'),
                          ))
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

                            return _animatedItem(i, AppCard(
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
                                        final allBytes = files.map((f) => base64Decode(f['file_data'] as String)).toList();
                                        return ScaleOnTap(
                                          onTap: () => _showFullImage(bytes, file['file_name'] ?? '', allImages: allBytes, initialIndex: fi),
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

  /// Staggered entrance for list items (capped so long lists stay snappy).
  Widget _animatedItem(int i, Widget child) => child
      .animate(delay: (40 * (i > 8 ? 8 : i)).ms)
      .fadeIn(duration: 250.ms)
      .slideY(begin: 0.08, curve: Curves.easeOutCubic);

  void _showFullImage(Uint8List bytes, String name, {List<Uint8List>? allImages, int initialIndex = 0}) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) => _FullImageViewer(
        images: allImages ?? [bytes],
        names: allImages != null ? List.generate(allImages.length, (i) => name) : [name],
        initialIndex: allImages != null ? initialIndex : 0,
      ),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ));
  }
}

// ═══════════════════════════════════════════════════════
// FULL-SCREEN IMAGE VIEWER WITH PINCH-ZOOM & GALLERY
// ═══════════════════════════════════════════════════════
class _FullImageViewer extends StatefulWidget {
  final List<Uint8List> images;
  final List<String> names;
  final int initialIndex;
  const _FullImageViewer({required this.images, required this.names, this.initialIndex = 0});
  @override
  State<_FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<_FullImageViewer> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Swipeable image gallery
        PageView.builder(
          controller: _pageCtrl,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.memory(widget.images[i], fit: BoxFit.contain),
              ),
            ),
          ),
        ),

        // Top bar with close button and file name
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(children: [
                IconButton(
                  icon: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                if (widget.names[_current].isNotEmpty)
                  Flexible(child: Text(widget.names[_current], style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
                const Spacer(),
                const SizedBox(width: 48),
              ]),
            ),
          ),
        ),

        // Page indicator dots (only if multiple images)
        if (widget.images.length > 1)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _current == i ? 24 : 8, height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _current == i ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),
              ),
            ),
          ),
      ]),
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

    HapticFeedback.mediumImpact();
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

      final result = await OfflineRepository.addHealthRecord({
        'title': _titleCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'files': filesData.isEmpty ? null : filesData,
      });

      widget.onCreated();
      if (mounted) {
        AppFeedback.showWriteResult(context, result, successMessage: l.translate('record_created'));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('save_failed'));
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
