import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class ManageCoachesScreen extends StatefulWidget {
  const ManageCoachesScreen({super.key});
  @override
  State<ManageCoachesScreen> createState() => _ManageCoachesScreenState();
}

class _ManageCoachesScreenState extends State<ManageCoachesScreen> {
  List<dynamic> coaches = [];
  List<dynamic> branches = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([ApiService().get('/head-coach/coaches'), ApiService().get('/head-coach/branches')]);
      coaches = results[0].data;
      branches = results[1].data;
    } catch (_) {
      if (mounted) _msg(AppLocalizations.of(context).translate('failed_to_load'), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _msg(String msg, {bool error = false}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? AppColors.error : AppColors.success));

  String _branchName(int? id) => branches.where((b) => b['id'] == id).map((b) => b['name'] as String).firstOrNull ?? AppLocalizations.of(context).translate('unassigned');

  // ═══════════════════════════════════════════════════════
  // CREATE COACH - Bottom Sheet
  // ═══════════════════════════════════════════════════════
  void _showCreateSheet() {
    final l = AppLocalizations.of(context);
    if (branches.isEmpty) { _msg(l.translate('no_branches'), error: true); return; }
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    int selectedBranch = branches.first['id'];
    bool creating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),

                // Header
                Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_add_rounded, color: AppColors.accent, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.translate('new_coach'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    Text(l.translate('password_auto_gen'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ])),
                ]),
                const SizedBox(height: 24),

                // Fields
                _sheetField(l.translate('full_name'), nameCtrl, Icons.person_outline_rounded),
                _sheetField(l.translate('email'), emailCtrl, Icons.email_outlined, type: TextInputType.emailAddress),
                _sheetField(l.translate('phone'), phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
                const SizedBox(height: 8),

                // Branch selector
                Align(alignment: Alignment.centerLeft, child: Text(l.translate('branch'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: branches.map((b) {
                      final active = b['id'] == selectedBranch;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedBranch = b['id']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: active ? AppColors.accent : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(22),
                              border: active ? null : Border.all(color: AppColors.divider),
                            ),
                            child: Center(child: Text(b['name'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textSecondary))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: creating ? null : () async {
                      if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) { _msg(l.translate('name_email_required'), error: true); return; }
                      setSheetState(() => creating = true);
                      try {
                        final res = await ApiService().post('/head-coach/coaches', data: {
                          'name': nameCtrl.text.trim(), 'email': emailCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(), 'branch_id': selectedBranch,
                        });
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _showCredentialsSheet(res.data['email'], res.data['password'], nameCtrl.text.trim());
                        _loadData();
                      } catch (e) {
                        _msg(_extractError(e, l.translate('failed_create_coach')), error: true);
                        setSheetState(() => creating = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: creating
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(l.translate('create_coach')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // CREDENTIALS SHEET
  // ═══════════════════════════════════════════════════════
  void _showCredentialsSheet(String email, String password, [String? coachName]) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        decoration: const BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),

            // Success icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 28),
            ),
            const SizedBox(height: 16),
            Text(coachName != null ? '$coachName ${l.translate('created_text')}' : l.translate('coach_credentials'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(l.translate('share_credentials'), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            // Credential cards
            _credCard(Icons.email_outlined, l.translate('email'), email),
            const SizedBox(height: 10),
            _credCard(Icons.key_rounded, l.translate('password'), password),
            const SizedBox(height: 24),

            // Actions
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: 'Email: $email\nPassword: $password'));
                    _msg(l.translate('credentials_copied'));
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(l.translate('copy_all')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(l.translate('done')))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _credCard(IconData icon, String label, String value) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        _msg('$label copied!');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.3)),
          ])),
          const Icon(Icons.copy_rounded, size: 16, color: AppColors.textTertiary),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // EDIT - Bottom Sheet
  // ═══════════════════════════════════════════════════════
  void _showEditSheet(Map<String, dynamic> coach) {
    final l = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: coach['name'] ?? '');
    final emailCtrl = TextEditingController(text: coach['email'] ?? '');
    final phoneCtrl = TextEditingController(text: coach['phone'] ?? '');
    int selectedBranch = coach['branch_id'] ?? (branches.isNotEmpty ? branches.first['id'] : 0);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
                Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text((coach['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)))),
                  const SizedBox(width: 12),
                  Text(l.translate('edit_coach'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ]),
                const SizedBox(height: 24),
                _sheetField(l.translate('name'), nameCtrl, Icons.person_outline_rounded),
                _sheetField(l.translate('email'), emailCtrl, Icons.email_outlined, type: TextInputType.emailAddress),
                _sheetField(l.translate('phone'), phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: Text(l.translate('branch'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5))),
                const SizedBox(height: 8),
                SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, children: branches.map((b) {
                  final active = b['id'] == selectedBranch;
                  return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                    onTap: () => setSheetState(() => selectedBranch = b['id']),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: active ? AppColors.accent : AppColors.surfaceLight, borderRadius: BorderRadius.circular(22), border: active ? null : Border.all(color: AppColors.divider)),
                      child: Center(child: Text(b['name'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textSecondary)))),
                  ));
                }).toList())),
                const SizedBox(height: 28),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: saving ? null : () async {
                    setSheetState(() => saving = true);
                    try {
                      await ApiService().put('/head-coach/coaches/${coach['id']}', data: {'name': nameCtrl.text.trim(), 'email': emailCtrl.text.trim(), 'phone': phoneCtrl.text.trim(), 'branch_id': selectedBranch});
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _msg(l.translate('coach_updated'));
                      _loadData();
                    } catch (e) { _msg(_extractError(e, l.translate('failed_generic')), error: true); setSheetState(() => saving = false); }
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(l.translate('save_changes')),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // RESET PASSWORD
  // ═══════════════════════════════════════════════════════
  void _showResetSheet(Map<String, dynamic> coach) {
    final l = AppLocalizations.of(context);
    final passCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          Text('${l.translate('reset_password_for')} ${coach['name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _sheetField(l.translate('new_password'), passCtrl, Icons.lock_outline_rounded, obscure: true),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (passCtrl.text.trim().isEmpty) return;
              try {
                await ApiService().post('/head-coach/coaches/${coach['id']}/reset-password', data: {'new_password': passCtrl.text.trim()});
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _msg(l.translate('password_reset_done'));
                _loadData();
              } catch (_) { _msg(l.translate('failed_generic'), error: true); }
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(l.translate('reset_password')),
          )),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ASSIGN BRANCH
  // ═══════════════════════════════════════════════════════
  void _showAssignBranchSheet(Map<String, dynamic> coach) {
    final l = AppLocalizations.of(context);
    int? selectedBranch = coach['branch_id'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          decoration: const BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.swap_horiz_rounded, color: AppColors.info, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.translate('assign_branch'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text(coach['name'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ])),
              ]),
              const SizedBox(height: 20),
              ...branches.map((b) {
                final active = b['id'] == selectedBranch;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setSheetState(() => selectedBranch = b['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: active ? AppColors.accent.withValues(alpha: 0.08) : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: active ? AppColors.accent : AppColors.divider, width: active ? 2 : 1),
                      ),
                      child: Row(children: [
                        Icon(Icons.location_city_rounded, size: 20, color: active ? AppColors.accent : AppColors.textTertiary),
                        const SizedBox(width: 12),
                        Expanded(child: Text(b['name'], style: TextStyle(fontSize: 15, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? AppColors.accent : AppColors.textPrimary))),
                        if (active) const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 22),
                      ]),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () async {
                  if (selectedBranch == null) return;
                  try {
                    await ApiService().put('/head-coach/coaches/${coach['id']}', data: {'branch_id': selectedBranch});
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _msg(l.translate('branch_assigned'));
                    _loadData();
                  } catch (e) { _msg(_extractError(e, l.translate('failed_generic')), error: true); }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(l.translate('assign_branch')),
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // DELETE
  // ═══════════════════════════════════════════════════════
  void _deleteCoach(int id, String name) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(l.translate('delete_coach')), content: Text('${l.translate('delete_confirm')} $name ${l.translate('remove_permanently')}'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.translate('cancel'))), TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: Text(l.translate('delete')))],
    ));
    if (ok != true) return;
    try { await ApiService().delete('/head-coach/coaches/$id'); _msg(l.translate('coach_deleted')); _loadData(); } catch (_) { _msg(l.translate('failed_generic'), error: true); }
  }

  // ═══════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════
  Widget _sheetField(String label, TextEditingController ctrl, IconData icon, {TextInputType? type, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl, keyboardType: type, obscureText: obscure,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(hintText: label, prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20)),
      ),
    );
  }

  String _extractError(dynamic e, String fallback) {
    if (e is DioException && e.response?.data != null) return e.response!.data['detail']?.toString() ?? fallback;
    return fallback;
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: ShimmerList(count: 4));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            FadeSlideIn(
              child: HeroHeader(
                title: AppLocalizations.of(context).translate('coaches'),
                subtitle: '${coaches.length}',
                leading: HeaderIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.go('/head-coach-branches')),
                trailing: HeaderIconButton(icon: Icons.person_add_rounded, onTap: _showCreateSheet),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accent,
        child: coaches.isEmpty
            ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                const SizedBox(height: 60),
                EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: AppLocalizations.of(context).translate('no_coaches'),
                  actionLabel: AppLocalizations.of(context).translate('add_first_coach'),
                  onAction: _showCreateSheet,
                ),
              ])
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 20),
                itemCount: coaches.length,
                itemBuilder: (_, i) {
                  final c = Map<String, dynamic>.from(coaches[i]);
                  final hasPassword = c['plain_password'] != null && c['plain_password'].toString().isNotEmpty;

                  return FadeSlideIn(
                    delay: i * 60,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        child: Column(
                          children: [
                            // Coach info row
                            Row(children: [
                              // Avatar
                              GradientAvatar(name: c['name'] ?? '?', size: 48),
                              const SizedBox(width: 14),
                              // Info
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(c['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text(c['email'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ])),
                            ]),
                            const SizedBox(height: 14),

                            // Branch + phone row
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10)),
                              child: Row(children: [
                                const Icon(Icons.location_city_rounded, size: 15, color: AppColors.accent),
                                const SizedBox(width: 6),
                                Text(_branchName(c['branch_id']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                if (c['phone'] != null && c['phone'].toString().isNotEmpty) ...[
                                  const SizedBox(width: 16),
                                  const Icon(Icons.phone_rounded, size: 14, color: AppColors.textTertiary),
                                  const SizedBox(width: 4),
                                  Text(c['phone'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                ],
                              ]),
                            ),
                            const SizedBox(height: 12),

                            // Action buttons row
                            Row(children: [
                              if (hasPassword) _actionChip(Icons.key_rounded, AppLocalizations.of(context).translate('credentials'), AppColors.accent, () => _showCredentialsSheet(c['email'] ?? '', c['plain_password'] ?? '')),
                              if (hasPassword) const SizedBox(width: 8),
                              _actionChip(Icons.swap_horiz_rounded, AppLocalizations.of(context).translate('branch_label'), AppColors.info, () => _showAssignBranchSheet(c)),
                              const SizedBox(width: 8),
                              _actionChip(Icons.edit_rounded, AppLocalizations.of(context).translate('edit'), AppColors.primary, () => _showEditSheet(c)),
                              const SizedBox(width: 8),
                              _actionChip(Icons.lock_reset_rounded, AppLocalizations.of(context).translate('reset'), AppColors.warning, () => _showResetSheet(c)),
                              const Spacer(),
                              ScaleOnTap(
                                onTap: () => _deleteCoach(c['id'], c['name'] ?? ''),
                                child: Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(AppRadius.sm)),
                                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _actionChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}
