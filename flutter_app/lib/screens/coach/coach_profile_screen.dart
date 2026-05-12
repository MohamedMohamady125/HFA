import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
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
  void initState() { super.initState(); _fetchDetails(); }

  Future<void> _fetchDetails() async {
    try {
      final res = await ApiService().get('/users/me');
      if (mounted) setState(() => branchName = res.data['branch_name'] ?? '');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile card
              AppCard(
                child: Column(
                  children: [
                    CircleAvatar(radius: 36, backgroundColor: AppColors.accent, child: Text((auth.userName ?? 'C')[0].toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white))),
                    const SizedBox(height: 16),
                    Text(auth.userName ?? 'Coach', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(branchName.isNotEmpty ? branchName : 'Branch', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 4),
                    Text(auth.userEmail ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Align(alignment: Alignment.centerLeft, child: SectionHeader(title: l.translate('settings'))),
              _menuItem(Icons.person_outline_rounded, l.translate('edit_profile'), () => context.push('/edit-profile')),
              _menuItem(Icons.lock_outline_rounded, l.translate('change_password'), () => context.push('/change-password')),
              _menuItem(Icons.fact_check_outlined, l.translate('attendance_summary'), () => context.push('/coach-manage/attendance')),
              if (auth.role == 'head_coach') ...[
                const SizedBox(height: 8),
                const Align(alignment: Alignment.centerLeft, child: SectionHeader(title: 'Head Coach')),
                _menuItem(Icons.people_rounded, l.translate('manage_coaches'), () => context.go('/head-coach-manage-coaches')),
                _menuItem(Icons.swap_horiz_rounded, 'Switch Branch', () => context.go('/head-coach-branches')),
              ],
              const SizedBox(height: 8),
              _languageCard(context, l),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async { await auth.logout(); if (context.mounted) context.go('/guest-home'); },
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                  child: Text(l.translate('logout')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageCard(BuildContext context, AppLocalizations l) {
    final localeProvider = context.watch<LocaleProvider>();
    return AppCard(
      onTap: () => localeProvider.toggleLocale(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        const Icon(Icons.language_rounded, color: AppColors.accent, size: 22),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.translate('language'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          Text(l.translate('language_current'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        Text(localeProvider.locale.languageCode == 'en' ? '\u0639\u0631\u0628\u064A' : 'EN', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
      ]),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
        ]),
      ),
    );
  }
}
