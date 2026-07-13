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
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar: language toggle + head coach access
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _langPill(localeProvider.locale.languageCode == 'en' ? '\u0639\u0631\u0628\u064A' : 'EN', () => localeProvider.toggleLocale()),
                    HeaderIconButton(
                      icon: Icons.shield_outlined,
                      onTap: () => context.push('/head-coach-login'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xxxl),
                      // Animated logo
                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 104, height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 36)],
                          ),
                          child: ClipOval(child: Image.asset('assets/images/hfanew.png', fit: BoxFit.cover)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      FadeSlideIn(
                        delay: 60,
                        child: Text('HFA', style: AppTypography.displayXL.copyWith(color: Colors.white, letterSpacing: 10)),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      FadeSlideIn(
                        delay: 120,
                        child: Text(
                          l.translate('swimming_academy'),
                          style: AppTypography.overline.copyWith(color: Colors.white.withValues(alpha: 0.7), letterSpacing: 4),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      FadeSlideIn(
                        delay: 180,
                        child: Text(
                          l.translate('welcome_title'),
                          textAlign: TextAlign.center,
                          style: AppTypography.displayMedium.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FadeSlideIn(
                        delay: 240,
                        child: Text(
                          l.translate('branch_count'),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      // Primary CTA — login
                      FadeSlideIn(
                        delay: 300,
                        child: SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            label: l.translate('login'),
                            onPressed: () => context.push('/login'),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Register — frosted card button
                      FadeSlideIn(
                        delay: 360,
                        child: _frostedButton(
                          label: l.translate('register'),
                          icon: Icons.person_add_alt_1_rounded,
                          onTap: () => context.push('/register'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Branches — frosted card
                      FadeSlideIn(
                        delay: 420,
                        child: _frostedCard(
                          onTap: () => context.push('/branches'),
                          child: Row(children: [
                            const IconBadge(icon: Icons.location_on_rounded, color: Colors.white, size: 44),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(l.translate('our_branches'), style: AppTypography.overline.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                              const SizedBox(height: 3),
                              Text(l.translate('branch_count'), style: AppTypography.titleMedium.copyWith(color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(l.translate('view_branches'), style: AppTypography.caption.copyWith(color: AppColors.accentLight)),
                            ])),
                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
                          ]),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Parent access — frosted card
                      FadeSlideIn(
                        delay: 480,
                        child: _frostedCard(
                          onTap: () => context.push('/parent-code'),
                          child: Row(children: [
                            const IconBadge(icon: Icons.family_restroom_rounded, color: Colors.white, size: 44),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(l.translate('parent_access'), style: AppTypography.titleMedium.copyWith(color: Colors.white)),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
                          ]),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Coach login — subtle text link
                      FadeSlideIn(
                        delay: 540,
                        child: TextButton.icon(
                          onPressed: () => context.push('/admin-login'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.7),
                            minimumSize: const Size(48, 48),
                          ),
                          icon: const Icon(Icons.shield_outlined, size: 16),
                          label: Text(
                            l.translate('coach_login'),
                            style: AppTypography.label.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _frostedCard({required VoidCallback onTap, required Widget child}) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
        ),
        child: child,
      ),
    );
  }

  Widget _frostedButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }

  Widget _langPill(String label, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}
