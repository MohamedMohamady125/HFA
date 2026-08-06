import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/refresh_bus.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> with LiveRefreshMixin {
  Timer? _pollTimer;
  bool _checking = false;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    // Poll every 5 seconds to check if the coach has approved
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkApproval());
    // Also check right away (covers the push-notification arrival case)
    _checkApproval();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // A push (approval/rejection) fires RefreshBus → re-check instantly.
  @override
  void onLiveRefresh() => _checkApproval();

  Future<void> _checkApproval() async {
    if (_checking || _handled) return;
    _checking = true;
    try {
      final auth = context.read<AuthProvider>();
      final status = await auth.checkApprovalStatus();
      if (!mounted || _handled) return;
      if (status == 'approved') {
        _handled = true;
        final role = auth.role;
        if (role == 'head_coach') {
          context.go('/head-coach-branches');
        } else if (role == 'coach') {
          context.go('/coach/home');
        } else {
          context.go('/athlete/home');
        }
      } else if (status == 'rejected') {
        _handled = true;
        _pollTimer?.cancel();
        await _showRejectedDialog();
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _showRejectedDialog() async {
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 40),
        title: Text(l.translate('registration_rejected'), textAlign: TextAlign.center),
        content: Text(l.translate('registration_rejected_message'), textAlign: TextAlign.center, style: AppTypography.bodyMedium),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.translate('ok')),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/guest-home');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  FadeSlideIn(
                    child: EmptyState(
                      icon: Icons.hourglass_top_rounded,
                      title: l.translate('pending_approval'),
                      message: l.translate('pending_message'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FadeSlideIn(
                    delay: 60,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.accent.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FadeSlideIn(
                    delay: 120,
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) context.go('/guest-home');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5), width: 1.5),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: Text(l.translate('logout')),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
