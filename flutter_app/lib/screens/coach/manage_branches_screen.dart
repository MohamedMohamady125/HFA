import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../services/offline/offline_repository.dart';
import '../../services/offline/connectivity_service.dart';
import '../../services/refresh_bus.dart';
import '../../widgets/app_feedback.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class ManageBranchesScreen extends StatefulWidget {
  const ManageBranchesScreen({super.key});
  @override
  State<ManageBranchesScreen> createState() => _ManageBranchesScreenState();
}

class _ManageBranchesScreenState extends State<ManageBranchesScreen> with LiveRefreshMixin {
  List<dynamic> branches = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  @override
  void onLiveRefresh() { _fetchBranches(); }

  Future<void> _fetchBranches() async {
    try {
      // Cache-first read with background refresh.
      final data = await OfflineRepository.getPublicBranches(
        onFresh: (fresh) { if (mounted && fresh is List) setState(() => branches = fresh); },
      );
      branches = data;
    } catch (_) {
      // Keep whatever we have; errors surface via empty state / snackbars on actions.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Writes on this screen are online-only. Returns true (and warns) if offline.
  bool _blockIfOffline() {
    if (ConnectivityService.isOnline) return false;
    AppFeedback.showError(context, Exception(),
        fallback: AppLocalizations.of(context).translate('offline_manage_branches'));
    return true;
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _openBranchSheet({Map<String, dynamic>? branch}) async {
    final l = AppLocalizations.of(context);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BranchFormSheet(branch: branch),
    );
    if (saved == true) {
      _showSnack(l.translate('branch_saved'));
      setState(() => loading = true);
      await _fetchBranches();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> branch) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showModalBottomSheet<bool>(
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
            child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 28),
          ),
          const SizedBox(height: 16),
          Text(l.translate('delete_branch'), style: AppTypography.titleLarge.copyWith(color: AppColors.error)),
          const SizedBox(height: 8),
          Text(l.translate('delete_branch_confirm'), style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: AppColors.divider)),
              child: Text(l.translate('cancel'), style: TextStyle(color: AppColors.textSecondary)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
              child: Text(l.translate('delete'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )),
          ]),
        ]),
      ),
    );
    if (confirmed != true) return;
    if (_blockIfOffline()) return;

    try {
      await ApiService().delete('/branches/${branch['id']}');
      _showSnack(l.translate('branch_deleted'));
      setState(() => loading = true);
      await _fetchBranches();
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('server_error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          HeroHeader(
            title: l.translate('manage_branches'),
            leading: HeaderIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.canPop() ? context.pop() : context.go('/head-coach-branches'),
            ),
            trailing: HeaderIconButton(
              icon: Icons.add_rounded,
              onTap: () => _openBranchSheet(),
            ),
          ),
          Expanded(
            child: loading
                ? const ShimmerList(count: 5)
                : branches.isEmpty
                    ? (!ConnectivityService.isOnline
                        ? EmptyState(
                            icon: Icons.wifi_off_rounded,
                            title: l.translate('no_connection'),
                            message: l.translate('offline_manage_reconnect'),
                          )
                        : EmptyState(
                            icon: Icons.location_city_rounded,
                            title: l.translate('no_branches_found'),
                            actionLabel: l.translate('add_branch'),
                            onAction: () => _openBranchSheet(),
                          ))
                    : RefreshIndicator(
                        onRefresh: _fetchBranches,
                        color: AppColors.accent,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
                          itemCount: branches.length,
                          itemBuilder: (_, i) => _branchCard(Map<String, dynamic>.from(branches[i]), i, l),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _branchCard(Map<String, dynamic> b, int index, AppLocalizations l) {
    final name = b['name']?.toString() ?? '';
    final address = b['address']?.toString() ?? '';
    final hasPhone = (b['phone']?.toString() ?? '').isNotEmpty;
    final hasWhatsapp = (b['whatsapp']?.toString() ?? '').isNotEmpty;
    final hasVideo = (b['video_url']?.toString() ?? '').isNotEmpty;
    final hasSchedule = (b['practice_days']?.toString() ?? '').isNotEmpty;

    return FadeSlideIn(
      delay: index * 50,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const IconBadge(icon: Icons.store_rounded, color: AppColors.accent, size: 44),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: AppTypography.titleLarge),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(address, style: AppTypography.caption),
                  ],
                ]),
              ),
              IconButton(
                onPressed: () => _openBranchSheet(branch: b),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: const Icon(Icons.edit_rounded, color: AppColors.accent, size: 22),
                tooltip: l.translate('edit_branch'),
              ),
              IconButton(
                onPressed: () => _confirmDelete(b),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                tooltip: l.translate('delete_branch'),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (hasPhone) StatusBadge(label: l.translate('phone'), color: AppColors.success),
                if (hasWhatsapp) StatusBadge(label: l.translate('whatsapp'), color: AppColors.success),
                if (hasVideo) StatusBadge(label: l.translate('video_url_label'), color: AppColors.info),
                if (hasSchedule) StatusBadge(label: l.translate('practice_schedule'), color: AppColors.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchFormSheet extends StatefulWidget {
  final Map<String, dynamic>? branch;
  const _BranchFormSheet({this.branch});

  @override
  State<_BranchFormSheet> createState() => _BranchFormSheetState();
}

class _BranchFormSheetState extends State<_BranchFormSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.branch?['name']?.toString() ?? '');
  late final TextEditingController _address = TextEditingController(text: widget.branch?['address']?.toString() ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.branch?['phone']?.toString() ?? '');
  late final TextEditingController _whatsapp = TextEditingController(text: widget.branch?['whatsapp']?.toString() ?? '');
  late final TextEditingController _videoUrl = TextEditingController(text: widget.branch?['video_url']?.toString() ?? '');
  late final TextEditingController _practiceDays = TextEditingController(text: widget.branch?['practice_days']?.toString() ?? '');
  bool _saving = false;

  bool get _isEdit => widget.branch != null;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _videoUrl.dispose();
    _practiceDays.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.translate('fill_all_fields')),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    if (!ConnectivityService.isOnline) {
      final l = AppLocalizations.of(context);
      AppFeedback.showError(context, Exception(),
          fallback: l.translate('offline_manage_branches'));
      return;
    }

    setState(() => _saving = true);
    final data = {
      'name': _name.text.trim(),
      'address': _address.text.trim(),
      'phone': _phone.text.trim(),
      'whatsapp': _whatsapp.text.trim(),
      'video_url': _videoUrl.text.trim(),
      'practice_days': _practiceDays.text.trim(),
    };

    try {
      if (_isEdit) {
        await ApiService().put('/branches/${widget.branch!['id']}', data: data);
      } else {
        await ApiService().post('/branches/', data: data);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, e, fallback: l.translate('server_error'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
              ),
              Text(
                l.translate(_isEdit ? 'edit_branch' : 'add_branch'),
                style: AppTypography.displayMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppFormField(
                label: l.translate('branch_name_label'),
                controller: _name,
                prefixIcon: Icons.store_rounded,
              ),
              AppFormField(
                label: l.translate('address'),
                controller: _address,
                prefixIcon: Icons.location_on_rounded,
              ),
              AppFormField(
                label: l.translate('phone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_rounded,
              ),
              AppFormField(
                label: l.translate('whatsapp'),
                controller: _whatsapp,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.chat_rounded,
              ),
              AppFormField(
                label: l.translate('video_url_label'),
                controller: _videoUrl,
                keyboardType: TextInputType.url,
                prefixIcon: Icons.play_circle_rounded,
              ),
              Text(l.translate('practice_schedule'), style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _practiceDays,
                maxLines: 4,
                minLines: 3,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                decoration: InputDecoration(hintText: l.translate('practice_schedule')),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l.translate('practice_schedule_helper'), style: AppTypography.caption),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: l.translate('save'),
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
