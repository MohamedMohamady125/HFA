import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class HeadCoachBranchesScreen extends StatefulWidget {
  const HeadCoachBranchesScreen({super.key});
  @override
  State<HeadCoachBranchesScreen> createState() => _HeadCoachBranchesScreenState();
}

class _HeadCoachBranchesScreenState extends State<HeadCoachBranchesScreen> {
  List<dynamic> branches = [];
  bool loading = true;
  int? _switchingId;

  @override
  void initState() { super.initState(); _fetchBranches(); }

  Future<void> _fetchBranches() async {
    try { final res = await ApiService().get('/head-coach/branches'); branches = res.data; }
    catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _switchToBranch(Map<String, dynamic> branch) async {
    setState(() => _switchingId = branch['id']);
    try {
      await ApiService().post('/head-coach/select-branch/${branch['id']}');
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored == null) return;
      final authUser = Map<String, dynamic>.from(jsonDecode(stored));
      authUser['branch_id'] = branch['id'];
      authUser['branch_name'] = branch['name'];
      await prefs.setString('authUser', jsonEncode(authUser));
      if (!mounted) return;
      final nav = GoRouter.of(context);
      await context.read<AuthProvider>().login(authUser);
      nav.go('/coach/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failed_switch')), backgroundColor: AppColors.error));
    } finally { if (mounted) setState(() => _switchingId = null); }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    context.go('/guest-home');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (loading) return const Scaffold(body: ShimmerList(count: 5));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlideIn(
              child: HeroHeader(
                title: l.translate('head_coach'),
                subtitle: l.translate('select_branch_manage'),
                trailing: HeaderIconButton(icon: Icons.logout_rounded, onTap: _logout),
                bottom: Row(children: [
                  StatChip(icon: Icons.location_city_rounded, value: '${branches.length}', label: l.translate('branch_label')),
                ]),
              ),
            ),
            Expanded(
              child: branches.isEmpty
                  ? EmptyState(icon: Icons.location_city_rounded, title: l.translate('no_branches'))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
                      itemCount: branches.length + 2,
                      itemBuilder: (_, index) {
                        if (index == 0) {
                          return FadeSlideIn(
                            delay: 50,
                            child: ActionTile(
                              icon: Icons.people_rounded,
                              title: l.translate('manage_coaches'),
                              color: AppColors.info,
                              onTap: () => context.go('/head-coach-manage-coaches'),
                            ),
                          );
                        }
                        if (index == 1) {
                          return FadeSlideIn(
                            delay: 75,
                            child: ActionTile(
                              icon: Icons.store_rounded,
                              title: l.translate('manage_branches'),
                              color: AppColors.warning,
                              onTap: () => context.go('/head-coach-manage-branches'),
                            ),
                          );
                        }
                        final i = index - 2;
                        final b = branches[i];
                        final isSwitching = _switchingId == b['id'];
                        return FadeSlideIn(
                          delay: 100 + (i * 50),
                          child: ScaleOnTap(
                            onTap: isSwitching ? null : () => _switchToBranch(Map<String, dynamic>.from(b)),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _switchingId != null && !isSwitching ? 0.4 : 1.0,
                              child: AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      gradient: isSwitching ? AppColors.accentGradient : null,
                                      color: isSwitching ? null : AppColors.accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: isSwitching
                                        ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
                                        : const Icon(Icons.location_city_rounded, color: AppColors.accent, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(b['name'] ?? '', style: AppTypography.titleMedium),
                                    if (b['address'] != null)
                                      Padding(padding: const EdgeInsets.only(top: 2), child: Text(b['address'], style: AppTypography.caption)),
                                  ])),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 22),
                                ]),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
