import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF0A2342), Color(0xFF1B3A5C), Color(0xFF0D4F8B)],
              ),
            ),
          ),
          // Decorative circles
          Positioned(top: -80, right: -60, child: _circle(240, AppColors.accent.withValues(alpha: 0.08))),
          Positioned(bottom: -40, left: -80, child: _circle(200, AppColors.accent.withValues(alpha: 0.06))),
          Positioned(top: 200, left: -40, child: _circle(120, AppColors.accent.withValues(alpha: 0.04))),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _iconBtn(localeProvider.locale.languageCode == 'en' ? '\u0639\u0631\u0628\u064A' : 'EN', () => localeProvider.toggleLocale()),
                      _iconBtn('Coach', () => context.push('/admin-login'), icon: Icons.shield_outlined),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Logo
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5)],
                          ),
                          child: ClipOval(child: Image.asset('assets/images/hfanew.png', fit: BoxFit.cover)),
                        ),
                        const SizedBox(height: 24),
                        const Text('HFA', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 6)),
                        const SizedBox(height: 4),
                        Text('SWIMMING ACADEMY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.accentLight.withValues(alpha: 0.8), letterSpacing: 4)),
                        const SizedBox(height: 12),
                        Text(l10n.translate('welcome_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(l10n.translate('branch_count'), style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
                        const SizedBox(height: 48),

                        // Info card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.translate('nearest_branch'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                                    const SizedBox(height: 4),
                                    Text(l10n.translate('branch_name'), style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),
                                    Text(l10n.translate('practice_time'), style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.push('/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(l10n.translate('login'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Register button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.push('/register'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(l10n.translate('register'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Head coach button
          Positioned(
            bottom: 40, right: 24,
            child: GestureDetector(
              onTap: () => context.push('/head-coach-login'),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.admin_panel_settings, color: AppColors.accent, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  Widget _iconBtn(String label, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white70, size: 16), const SizedBox(width: 6)],
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
