import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.translate('reset_password')), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.translate('forgot_password'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(l.translate('forgot_desc'), style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 32),
            TextField(keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: l.translate('email_address'), prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textTertiary))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.translate('reset_sent')), backgroundColor: AppColors.success)); context.pop(); }, child: Text(l.translate('send_reset')))),
          ],
        ),
      ),
    );
  }
}
