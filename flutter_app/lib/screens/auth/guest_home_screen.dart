import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => localeProvider.toggleLocale(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(20)),
                      child: Text(localeProvider.locale.languageCode == 'en' ? '\u0639\u0631\u0628\u064A' : 'EN', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/head-coach-login'),
                    child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.textSecondary, size: 20)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 2)]), child: ClipOval(child: Image.asset('assets/images/hfanew.png', fit: BoxFit.cover))),
                    const SizedBox(height: 20),
                    const Text('HFA', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 4)),
                    const SizedBox(height: 2),
                    Text(l.translate('swimming_academy'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary.withValues(alpha: 0.5), letterSpacing: 3)),
                    const SizedBox(height: 20),
                    Text(l.translate('welcome_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(l.translate('branch_count'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.translate('nearest_branch'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          const SizedBox(height: 4),
                          Text(l.translate('branch_name'), style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                          Text(l.translate('practice_time'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => context.push('/login'), child: Text(l.translate('login'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => context.push('/register'), child: Text(l.translate('register'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)))),
                    const SizedBox(height: 20),
                    TextButton.icon(onPressed: () => context.push('/admin-login'), icon: const Icon(Icons.shield_outlined, size: 18, color: AppColors.textSecondary), label: Text(l.translate('coach_login'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500))),
                    const SizedBox(height: 40),
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
