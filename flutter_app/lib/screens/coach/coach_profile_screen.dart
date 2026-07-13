import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/offline/offline_repository.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class CoachProfileScreen extends StatefulWidget {
  const CoachProfileScreen({super.key});
  @override
  State<CoachProfileScreen> createState() => CoachProfileScreenState();
}

class CoachProfileScreenState extends State<CoachProfileScreen> {
  String branchName = '';

  void silentRefresh() { _fetchDetails(); }

  @override
  void initState() {
    super.initState();
    final cached = OfflineRepository.getCached('/users/me');
    if (cached is Map) branchName = cached['branch_name']?.toString() ?? '';
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final data = await OfflineRepository.getUserMe();
      if (mounted) setState(() => branchName = data['branch_name'] ?? '');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            FadeSlideIn(
              child: HeroHeader(
                title: auth.userName ?? 'Coach',
                subtitle: auth.userEmail ?? '',
                leading: GradientAvatar(name: auth.userName ?? 'C', size: 52),
                bottom: Row(children: [
                  StatChip(
                    icon: Icons.location_on_rounded,
                    value: branchName.isNotEmpty ? branchName : l.translate('branch_label'),
                    label: l.translate('branch_label'),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(delay: 50, child: SectionHeader(title: l.translate('settings'))),
                    FadeSlideIn(delay: 100, child: ActionTile(
                      icon: Icons.person_outline_rounded,
                      title: l.translate('edit_profile'),
                      onTap: () => context.push('/edit-profile'),
                    )),
                    FadeSlideIn(delay: 150, child: ActionTile(
                      icon: Icons.lock_outline_rounded,
                      title: l.translate('change_password'),
                      color: AppColors.primary,
                      onTap: () => context.push('/change-password'),
                    )),
                    FadeSlideIn(delay: 200, child: ActionTile(
                      icon: Icons.fact_check_outlined,
                      title: l.translate('attendance_summary'),
                      color: AppColors.warning,
                      onTap: () => context.push('/coach-manage/attendance'),
                    )),

                    if (auth.role == 'head_coach') ...[
                      const SizedBox(height: AppSpacing.sm),
                      FadeSlideIn(delay: 250, child: SectionHeader(title: l.translate('head_coach'))),
                      FadeSlideIn(delay: 300, child: ActionTile(
                        icon: Icons.people_rounded,
                        title: l.translate('manage_coaches'),
                        color: AppColors.info,
                        onTap: () => context.go('/head-coach-manage-coaches'),
                      )),
                      FadeSlideIn(delay: 350, child: ActionTile(
                        icon: Icons.swap_horiz_rounded,
                        title: l.translate('switch_branch'),
                        color: AppColors.success,
                        onTap: () => context.go('/head-coach-branches'),
                      )),
                    ],

                    const SizedBox(height: AppSpacing.sm),
                    FadeSlideIn(delay: 400, child: ActionTile(
                      icon: Icons.language_rounded,
                      title: l.translate('language'),
                      subtitle: l.translate('language_current'),
                      onTap: () => localeProvider.toggleLocale(),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(localeProvider.locale.languageCode == 'en' ? '\u0639\u0631\u0628\u064A' : 'EN',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 22),
                      ]),
                    )),

                    const SizedBox(height: AppSpacing.xxl),
                    FadeSlideIn(delay: 450, child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
                      onPressed: () async { await auth.logout(); if (context.mounted) context.go('/guest-home'); },
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error, width: 1.5)),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(l.translate('logout')),
                    ))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
