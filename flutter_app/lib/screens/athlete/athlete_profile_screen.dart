import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/offline/offline_repository.dart';
import '../../services/offline/connectivity_service.dart';
import '../../widgets/app_feedback.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'health_history_screen.dart';

class AthleteProfileScreen extends StatefulWidget {
  const AthleteProfileScreen({super.key});
  @override
  State<AthleteProfileScreen> createState() => AthleteProfileScreenState();
}

class AthleteProfileScreenState extends State<AthleteProfileScreen> {
  Map<String, dynamic>? user;
  List<dynamic> attendance = [];
  String branchName = '';
  int labelCount = 3;
  Map<String, String> paymentHistory = {};

  // Measurements
  Map<String, TextEditingController> mCtrl = {};
  bool mEditable = true;
  final _mKeys = ['height', 'weight', 'arm', 'leg', 'fat', 'muscle'];

  // Events
  List<Map<String, TextEditingController>> eventCtrl = [];
  bool eventsEditable = true;

  void silentRefresh() { _fetchData(); }

  @override
  void initState() {
    super.initState();
    for (var k in _mKeys) {
      mCtrl[k] = TextEditingController();
    }
    eventCtrl.add({'name': TextEditingController(), 'time': TextEditingController()});
    _fetchData();
  }

  bool _mLoaded = false;
  bool _evLoaded = false;

  void _applyAttendance(dynamic data) {
    if (data is List) attendance = data;
  }

  void _applyBranch(dynamic data) {
    if (data is Map) branchName = data['name']?.toString() ?? branchName;
  }

  void _applySessionDates(dynamic data) {
    if (data is List && data.isNotEmpty) labelCount = data.length;
  }

  void _applyMeasurements(dynamic data) {
    if (mEditable && _mLoaded) return; // don't clobber while user is editing
    final mData = data is List ? data.firstOrNull : data;
    if (mData is Map) {
      for (var k in _mKeys) {
        mCtrl[k]!.text = mData[k]?.toString() ?? '';
      }
      mEditable = false;
      _mLoaded = true;
    }
  }

  void _applyEvents(dynamic data) {
    if (eventsEditable && _evLoaded) return; // don't clobber while user is editing
    if (data is List && data.isNotEmpty) {
      eventCtrl = data.map((e) => {
        'name': TextEditingController(text: e['event_name'] ?? ''),
        'time': TextEditingController(text: e['result_time']?.toString() ?? ''),
      }).toList();
      eventsEditable = false;
      _evLoaded = true;
    }
  }

  void _applyPayments(dynamic data) {
    if (data is Map) {
      paymentHistory = data.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('authUser');
    if (stored == null) return;
    user = jsonDecode(stored);
    final userId = user!['id'];
    final branchId = user!['branch_id'];

    // 1. Instant synchronous cache reads — data before first frame settles
    _applyAttendance(OfflineRepository.getCached('/attendance/athlete/$userId/week'));
    _applyBranch(OfflineRepository.getCached('/branches/$branchId'));
    _applySessionDates(OfflineRepository.getCached('/attendance/branch/$branchId/session-dates'));
    _applyMeasurements(OfflineRepository.getCached('/athlete/measurements'));
    _applyEvents(OfflineRepository.getCached('/athlete/performance-logs'));
    _applyPayments(OfflineRepository.getCached('/payments/$userId/status'));
    if (mounted) setState(() {});

    // 2. Cache-first reads with background refresh
    try {
      final results = await Future.wait([
        OfflineRepository.getAttendanceWeek(userId,
            onFresh: (d) { _applyAttendance(d); if (mounted) setState(() {}); }),
        OfflineRepository.getBranch(branchId,
            onFresh: (d) { _applyBranch(d); if (mounted) setState(() {}); }),
        OfflineRepository.getSessionDates(branchId,
            onFresh: (d) { _applySessionDates(d); if (mounted) setState(() {}); }),
        OfflineRepository.getMeasurements(
            onFresh: (d) { _applyMeasurements(d); if (mounted) setState(() {}); }),
        OfflineRepository.getPerformanceLogs(
            onFresh: (d) { _applyEvents(d); if (mounted) setState(() {}); }),
        OfflineRepository.getPaymentStatus(userId,
            onFresh: (d) { _applyPayments(d); if (mounted) setState(() {}); }),
      ]);
      _applyAttendance(results[0]);
      _applyBranch(results[1]);
      _applySessionDates(results[2]);
      _applyMeasurements(results[3]);
      _applyEvents(results[4]);
      _applyPayments(results[5]);
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Future<void> _saveMeasurements() async {
    HapticFeedback.mediumImpact();
    final l = AppLocalizations.of(context);
    final data = <String, dynamic>{};
    for (var k in _mKeys) {
      data[k] = double.tryParse(mCtrl[k]!.text) ?? 0;
    }
    try {
      final result = await OfflineRepository.saveMeasurements(data);
      if (!mounted) return;
      AppFeedback.showWriteResult(context, result, successMessage: l.translate('measurements_saved'));
      setState(() { mEditable = false; _mLoaded = true; });
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('save_failed'));
    }
  }

  Future<void> _saveEvents() async {
    HapticFeedback.mediumImpact();
    final l = AppLocalizations.of(context);
    final valid = eventCtrl.where((e) => e['name']!.text.isNotEmpty && e['time']!.text.isNotEmpty).toList();
    if (valid.isEmpty) return;
    try {
      var allSynced = true;
      final del = await OfflineRepository.deletePerformanceLogs();
      allSynced = allSynced && del.synced;
      for (var e in valid) {
        final r = await OfflineRepository.addPerformanceLog({
          'meet_name': 'Top Swim Event',
          'meet_date': DateTime.now().toIso8601String().split('T')[0],
          'event_name': e['name']!.text,
          'result_time': double.tryParse(e['time']!.text) ?? 0,
        });
        allSynced = allSynced && r.synced;
      }
      if (!mounted) return;
      AppFeedback.showWriteResult(context, WriteResult(synced: allSynced),
          successMessage: l.translate('events_saved'));
      setState(() { eventsEditable = false; _evLoaded = true; });
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('save_failed'));
    }
  }

  bool _requireOnline() {
    if (ConnectivityService.isOnline) return true;
    final l = AppLocalizations.of(context);
    AppFeedback.showError(context, Exception(),
        fallback: l.translate('offline_account'));
    return false;
  }

  Future<void> _showChangeEmail() async {
    if (!_requireOnline()) return;
    final emailCtrl = TextEditingController(text: user!['email'] ?? '');
    final passCtrl = TextEditingController();

    final l = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.translate('change_email'), style: const TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: l.translate('new_email'))),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: l.translate('confirm_password_label'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.translate('cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.translate('update'))),
        ],
      ),
    );

    if (result != true || emailCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) return;
    if (!mounted || !_requireOnline()) return;

    try {
      await ApiService().post('/auth/change-email', data: {'new_email': emailCtrl.text.trim(), 'password': passCtrl.text});
      // Update local stored user
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored != null) {
        final authUser = Map<String, dynamic>.from(jsonDecode(stored));
        authUser['email'] = emailCtrl.text.trim();
        await prefs.setString('authUser', jsonEncode(authUser));
        user = authUser;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.translate('email_updated')), backgroundColor: AppColors.success));
        setState(() {});
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('email_update_failed'));
    }
  }

  Future<void> _showChangePassword() async {
    if (!_requireOnline()) return;
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final l = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.translate('change_password'), style: const TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oldCtrl, obscureText: true, decoration: InputDecoration(labelText: l.translate('current_password'))),
              const SizedBox(height: 12),
              TextField(controller: newCtrl, obscureText: true, decoration: InputDecoration(labelText: l.translate('new_password'))),
              const SizedBox(height: 12),
              TextField(controller: confirmCtrl, obscureText: true, decoration: InputDecoration(labelText: l.translate('confirm_new_password'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.translate('cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.translate('update'))),
        ],
      ),
    );

    if (result != true) return;
    if (newCtrl.text != confirmCtrl.text) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.translate('passwords_no_match')), backgroundColor: AppColors.error));
      return;
    }
    if (newCtrl.text.isEmpty || oldCtrl.text.isEmpty) return;
    if (!mounted || !_requireOnline()) return;

    try {
      await ApiService().post('/auth/change-password', data: {'old_password': oldCtrl.text, 'new_password': newCtrl.text});
      if (mounted) AppFeedback.showSuccess(context, l.translate('password_changed'));
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('password_failed'));
    }
  }

  Future<void> _showDeleteAccount() async {
    if (!_requireOnline()) return;
    final passCtrl = TextEditingController();
    final l = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.translate('delete_account'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.translate('delete_account_confirm'), style: AppTypography.bodyMedium),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: l.translate('delete_account_password')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.translate('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.translate('delete_account')),
          ),
        ],
      ),
    );

    if (confirmed != true || passCtrl.text.isEmpty || !mounted) return;

    try {
      await ApiService().post('/auth/delete-account', data: {'password': passCtrl.text});
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
      if (mounted) {
        AppFeedback.showSuccess(context, l.translate('account_deleted'));
        context.go('/guest-home');
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e, fallback: l.translate('password_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (user == null) return const AppLoadingScreen();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.accent,
        edgeOffset: 140,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Profile Header ──
              FadeSlideIn(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 24),
                      child: Column(children: [
                        GradientAvatar(name: user!['name'] ?? 'U', size: 84),
                        const SizedBox(height: AppSpacing.md),
                        Text(user!['name'] ?? '', textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                        const SizedBox(height: AppSpacing.sm),
                        if (branchName.isNotEmpty)
                          StatusBadge(label: branchName, color: AppColors.accentLight),
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Column(children: [
                            _infoRow(Icons.email_rounded, l.translate('email'), user!['email'] ?? ''),
                            if (user!['phone'] != null && user!['phone'].toString().isNotEmpty)
                              _infoRow(Icons.phone_rounded, l.translate('phone'), user!['phone']),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Health History ──
                    FadeSlideIn(delay: 50, child: ActionTile(
                      icon: Icons.medical_information_rounded,
                      color: AppColors.error,
                      title: l.translate('health_history'),
                      subtitle: l.translate('health_history_desc'),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthHistoryScreen())),
                    )),

                    // ── Parent Access ──
                    FadeSlideIn(delay: 100, child: _buildParentAccess(l)),

                    // ── Attendance ──
                    const SizedBox(height: AppSpacing.xs),
                    FadeSlideIn(delay: 150, child: SectionHeader(
                      title: l.translate('attendance_tracker'),
                      trailing: TextButton(
                        onPressed: () => context.push('/athlete/attendance-history'),
                        child: Text(l.translate('view_calendar'), style: const TextStyle(color: AppColors.accent)),
                      ),
                    )),
                    FadeSlideIn(delay: 200, child: AppCard(
                      onTap: () => context.push('/athlete/attendance-history'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(labelCount, (i) {
                          final record = attendance.where((r) => r['day_number'] == i + 1).firstOrNull;
                          final status = record?['status'];
                          final color = status == 'present' ? AppColors.success : status == 'absent' ? AppColors.error : AppColors.textTertiary;
                          return Column(children: [
                            Text('${l.translate('day')} ${i + 1}', style: AppTypography.caption),
                            const SizedBox(height: AppSpacing.sm),
                            Icon(
                              status == 'present' ? Icons.check_circle_rounded : status == 'absent' ? Icons.cancel_rounded : Icons.remove_circle_outline,
                              color: color, size: 28,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              status == 'present' ? l.translate('present') : status == 'absent' ? l.translate('absent') : '-',
                              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                            ),
                          ]);
                        }),
                      ),
                    )),

                    // ── Payment History ──
                    const SizedBox(height: AppSpacing.xs),
                    FadeSlideIn(delay: 250, child: SectionHeader(title: l.translate('payment'))),
                    FadeSlideIn(delay: 300, child: AppCard(
                      child: paymentHistory.isEmpty
                          ? Center(child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                              child: Text(l.translate('no_payment_records'), style: AppTypography.bodyMedium),
                            ))
                          : Column(
                              children: paymentHistory.entries.toList().reversed.take(6).map((entry) {
                                final statusText = entry.value;
                                final color = statusText == 'paid' ? AppColors.success : statusText == 'late' ? AppColors.error : AppColors.warning;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key, style: AppTypography.bodyLarge),
                                      StatusBadge(label: statusText.toUpperCase(), color: color),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    )),

                    // ── Measurements ──
                    const SizedBox(height: AppSpacing.xs),
                    FadeSlideIn(delay: 350, child: SectionHeader(
                      title: l.translate('measurements'),
                      trailing: mEditable ? null : TextButton(
                        onPressed: () => setState(() => mEditable = true),
                        child: Text(l.translate('edit'), style: const TextStyle(color: AppColors.accent)),
                      ),
                    )),
                    FadeSlideIn(delay: 400, child: AppCard(
                      child: Column(
                        children: [
                          ..._mKeys.map((k) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Row(children: [
                              SizedBox(width: 100, child: Text(l.translate(k), style: AppTypography.label)),
                              Expanded(child: TextField(
                                controller: mCtrl[k],
                                keyboardType: TextInputType.number,
                                enabled: mEditable,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
                              )),
                            ]),
                          )),
                          if (mEditable) PrimaryButton(label: l.translate('save_measurements'), onPressed: _saveMeasurements),
                        ],
                      ),
                    )),

                    // ── Swim Events ──
                    const SizedBox(height: AppSpacing.xs),
                    FadeSlideIn(delay: 450, child: SectionHeader(
                      title: l.translate('swim_events'),
                      trailing: eventsEditable ? null : TextButton(
                        onPressed: () => setState(() => eventsEditable = true),
                        child: Text(l.translate('edit'), style: const TextStyle(color: AppColors.accent)),
                      ),
                    )),
                    FadeSlideIn(delay: 500, child: AppCard(
                      child: Column(
                        children: [
                          ...eventCtrl.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(children: [
                              Expanded(child: TextField(controller: e['name'], enabled: eventsEditable, decoration: InputDecoration(hintText: l.translate('event_name'), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: TextField(controller: e['time'], enabled: eventsEditable, decoration: InputDecoration(hintText: l.translate('time'), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
                            ]),
                          )),
                          if (eventCtrl.length < 5 && eventsEditable) TextButton.icon(
                            onPressed: () => setState(() => eventCtrl.add({'name': TextEditingController(), 'time': TextEditingController()})),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l.translate('add_event')),
                          ),
                          if (eventsEditable) PrimaryButton(label: l.translate('save_events'), onPressed: _saveEvents),
                        ],
                      ),
                    )),

                    // ── Settings ──
                    const SizedBox(height: AppSpacing.lg),
                    FadeSlideIn(delay: 550, child: SectionHeader(title: l.translate('settings'))),
                    FadeSlideIn(delay: 600, child: ActionTile(
                      icon: Icons.email_rounded,
                      color: AppColors.primary,
                      title: l.translate('change_email'),
                      onTap: _showChangeEmail,
                    )),
                    FadeSlideIn(delay: 650, child: ActionTile(
                      icon: Icons.lock_rounded,
                      color: AppColors.primary,
                      title: l.translate('change_password'),
                      onTap: _showChangePassword,
                    )),
                    FadeSlideIn(delay: 700, child: _languageToggle(context, l)),
                    FadeSlideIn(delay: 750, child: ActionTile(
                      icon: Icons.privacy_tip_outlined,
                      color: AppColors.accent,
                      title: l.translate('privacy_policy'),
                      onTap: () => launchUrl(Uri.parse('${ApiService.baseUrl}/privacy-policy'), mode: LaunchMode.externalApplication),
                    )),
                    FadeSlideIn(delay: 800, child: ActionTile(
                      icon: Icons.logout_rounded,
                      color: AppColors.error,
                      title: l.translate('logout'),
                      onTap: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) context.go('/guest-home');
                      },
                    )),
                    FadeSlideIn(delay: 850, child: ActionTile(
                      icon: Icons.delete_forever_rounded,
                      color: AppColors.error,
                      title: l.translate('delete_account'),
                      subtitle: l.translate('delete_account_desc'),
                      onTap: _showDeleteAccount,
                    )),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _parentCode;
  bool _generatingCode = false;

  Future<void> _generateParentCode() async {
    if (!_requireOnline()) return;
    HapticFeedback.mediumImpact();
    setState(() => _generatingCode = true);
    try {
      final res = await ApiService().post('/auth/generate-parent-code');
      if (mounted) setState(() => _parentCode = res.data['code']);
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        AppFeedback.showError(context, e, fallback: l.translate('save_failed'));
      }
    } finally {
      if (mounted) setState(() => _generatingCode = false);
    }
  }

  Widget _buildParentAccess(AppLocalizations l) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const IconBadge(icon: Icons.family_restroom_rounded, color: AppColors.accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.translate('parent_access'), style: AppTypography.titleMedium),
              Text(l.translate('parent_access_desc'), style: AppTypography.caption),
            ])),
          ]),
          const SizedBox(height: AppSpacing.lg),
          if (_parentCode != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Column(children: [
                Text(l.translate('your_code'), style: AppTypography.label),
                const SizedBox(height: 6),
                Text(_parentCode!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.accent, letterSpacing: 8)),
                const SizedBox(height: 4),
                Text(l.translate('code_expires'), style: AppTypography.caption),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _parentCode!));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.translate('copied')), backgroundColor: AppColors.success));
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text(l.translate('copy_code')),
              )),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: ElevatedButton.icon(
                onPressed: _generatingCode ? null : _generateParentCode,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l.translate('new_code')),
              )),
            ]),
          ] else
            PrimaryButton(
              label: l.translate('generate_code'),
              icon: Icons.key_rounded,
              loading: _generatingCode,
              onPressed: _generatingCode ? null : _generateParentCode,
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _languageToggle(BuildContext context, AppLocalizations l) {
    final localeProvider = context.watch<LocaleProvider>();
    return ActionTile(
      icon: Icons.language_rounded,
      color: AppColors.accent,
      title: l.translate('language'),
      subtitle: l.translate('language_current'),
      onTap: () => localeProvider.toggleLocale(),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(localeProvider.locale.languageCode == 'en' ? '\u0639\u0631\u0628\u064A' : 'EN', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
        const SizedBox(width: AppSpacing.xs),
        const Icon(Icons.swap_horiz_rounded, color: AppColors.textTertiary, size: 18),
      ]),
    );
  }

  @override
  void dispose() {
    for (var c in mCtrl.values) {
      c.dispose();
    }
    for (var e in eventCtrl) { e['name']?.dispose(); e['time']?.dispose(); }
    super.dispose();
  }
}
