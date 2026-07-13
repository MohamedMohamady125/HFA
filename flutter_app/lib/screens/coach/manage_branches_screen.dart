import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class ManageBranchesScreen extends StatefulWidget {
  const ManageBranchesScreen({super.key});
  @override
  State<ManageBranchesScreen> createState() => _ManageBranchesScreenState();
}

class _ManageBranchesScreenState extends State<ManageBranchesScreen> {
  List<dynamic> branches = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    try {
      final res = await ApiService().get('/branches/');
      branches = res.data is List ? res.data : [];
    } catch (_) {
      // Keep whatever we have; errors surface via empty state / snackbars on actions.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _errorDetail(Object e, String fallback) {
    if (e is DioException && e.response?.data is Map) {
      final detail = (e.response!.data as Map)['detail'];
      if (detail != null) return detail.toString();
    }
    return fallback;
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(l.translate('delete_branch'), style: AppTypography.titleLarge),
        content: Text(l.translate('delete_branch_confirm'), style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.translate('cancel'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.translate('delete'), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService().delete('/branches/${branch['id']}');
      _showSnack(l.translate('branch_deleted'));
      setState(() => loading = true);
      await _fetchBranches();
    } catch (e) {
      _showSnack(_errorDetail(e, l.translate('server_error')), error: true);
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
                    ? EmptyState(
                        icon: Icons.location_city_rounded,
                        title: l.translate('no_branches_found'),
                        actionLabel: l.translate('add_branch'),
                        onAction: () => _openBranchSheet(),
                      )
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
      String message = l.translate('server_error');
      if (e is DioException && e.response?.data is Map) {
        final detail = (e.response!.data as Map)['detail'];
        if (detail != null) message = detail.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ));
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
