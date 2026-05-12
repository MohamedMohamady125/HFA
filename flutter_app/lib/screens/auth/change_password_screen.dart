import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();

  Future<void> _handleChange() async {
    final l = AppLocalizations.of(context);
    try {
      await ApiService().post('/auth/change-password', data: {'old_password': _currentCtrl.text, 'new_password': _newCtrl.text});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.translate('password_changed')), backgroundColor: AppColors.success));
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.translate('password_failed')), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.translate('change_password')), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          AppFormField(label: l.translate('current_password'), controller: _currentCtrl, obscure: true),
          AppFormField(label: l.translate('new_password'), controller: _newCtrl, obscure: true),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _handleChange, child: Text(l.translate('update_password')))),
        ]),
      ),
    );
  }

  @override
  void dispose() { _currentCtrl.dispose(); _newCtrl.dispose(); super.dispose(); }
}
