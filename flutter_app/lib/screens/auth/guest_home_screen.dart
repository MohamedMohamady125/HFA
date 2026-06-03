import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});
  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoController.forward();
  }

  @override
  void dispose() { _logoController.dispose(); super.dispose(); }

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _pill(localeProvider.locale.languageCode == 'en' ? '\u0639\u0631\u0628\u064A' : 'EN', () => localeProvider.toggleLocale()),
                  IconButton(
                    icon: Icon(Icons.shield_outlined, color: AppColors.textTertiary, size: 20),
                    onPressed: () => context.push('/head-coach-login'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    // Animated logo
                    ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                          boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.25), blurRadius: 30, spreadRadius: 0)]),
                        child: ClipOval(child: Image.asset('assets/images/hfanew.png', fit: BoxFit.cover)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(delay: 200, child: const Text('HFA', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 8))),
                    FadeSlideIn(delay: 300, child: Text(l.translate('swimming_academy'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 4))),
                    const SizedBox(height: 28),
                    FadeSlideIn(delay: 400, child: Text(l.translate('welcome_title'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5))),
                    const SizedBox(height: 8),
                    FadeSlideIn(delay: 500, child: Text(l.translate('branch_count'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
                    const SizedBox(height: 40),

                    // Branch card
                    FadeSlideIn(delay: 600, child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.translate('nearest_branch'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 0.5)),
                          const SizedBox(height: 3),
                          Text(l.translate('branch_name'), style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                          Text(l.translate('practice_time'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ])),
                      ]),
                    )),
                    const SizedBox(height: 40),

                    // Buttons
                    FadeSlideIn(delay: 700, child: SizedBox(width: double.infinity, child: ElevatedButton(
                      onPressed: () => context.push('/login'),
                      child: Text(l.translate('login')),
                    ))),
                    const SizedBox(height: 12),
                    FadeSlideIn(delay: 800, child: SizedBox(width: double.infinity, child: OutlinedButton(
                      onPressed: () => context.push('/register'),
                      child: Text(l.translate('register')),
                    ))),
                    const SizedBox(height: 24),
                    FadeSlideIn(delay: 900, child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
                      onPressed: () => context.push('/parent-code'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: const BorderSide(color: AppColors.accent)),
                      icon: const Icon(Icons.family_restroom_rounded, size: 18),
                      label: Text(l.translate('parent_access')),
                    ))),
                    const SizedBox(height: 16),
                    FadeSlideIn(delay: 950, child: TextButton.icon(
                      onPressed: () => context.push('/admin-login'),
                      icon: const Icon(Icons.shield_outlined, size: 16, color: AppColors.textTertiary),
                      label: Text(l.translate('coach_login'), style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                    )),
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

  Widget _pill(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ),
    );
  }
}
