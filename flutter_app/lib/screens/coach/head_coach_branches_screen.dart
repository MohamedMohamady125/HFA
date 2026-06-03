import 'package:flutter/material.dart';
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
    context.go('/guest-home');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (loading) return const Scaffold(body: ShimmerList(count: 5));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.translate('head_coach'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(l.translate('select_branch_manage'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ])),
                IconButton(onPressed: _logout, icon: const Icon(Icons.logout_rounded, color: AppColors.textTertiary), tooltip: l.translate('logout')),
              ])),
              const SizedBox(height: 16),
              FadeSlideIn(delay: 100, child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: () => context.go('/head-coach-manage-coaches'),
                icon: const Icon(Icons.people_rounded, size: 18),
                label: Text(l.translate('manage_coaches')),
              ))),
              const SizedBox(height: 20),
              Expanded(
                child: branches.isEmpty
                    ? Center(child: Text(l.translate('no_branches'), style: const TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: branches.length,
                        itemBuilder: (_, i) {
                          final b = branches[i];
                          final isSwitching = _switchingId == b['id'];
                          return FadeSlideIn(
                            delay: 150 + (i * 60),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ScaleOnTap(
                                onTap: isSwitching ? null : () => _switchToBranch(Map<String, dynamic>.from(b)),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _switchingId != null && !isSwitching ? 0.4 : 1.0,
                                  child: AppCard(
                                    child: Row(children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(
                                          color: isSwitching ? AppColors.accent : AppColors.accent.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: isSwitching
                                            ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
                                            : const Icon(Icons.location_city_rounded, color: AppColors.accent, size: 22),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(b['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                        if (b['address'] != null) Text(b['address'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                      ])),
                                      const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                                    ]),
                                  ),
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
      ),
    );
  }
}
