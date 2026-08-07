import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/update_gate.dart';
import '../theme/app_theme.dart';

/// Blocking screen shown when the installed app is older than the server's
/// minimum required version. No way past it except updating.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final url = UpdateGate.required.value ?? '';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              FadeSlideIn(
                child: EmptyState(
                  icon: Icons.system_update_rounded,
                  title: l.translate('update_required'),
                  message: l.translate('update_required_message'),
                ),
              ),
              const Spacer(),
              if (url.isNotEmpty)
                FadeSlideIn(
                  delay: 120,
                  child: SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: l.translate('update_now'),
                      onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
