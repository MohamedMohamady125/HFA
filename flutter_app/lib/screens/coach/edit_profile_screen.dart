import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl, _emailCtrl;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.userName ?? '');
    _emailCtrl = TextEditingController(text: auth.userEmail ?? '');
  }

  Future<void> _handleSave() async {
    try {
      await ApiService().put('/coach/profile', data: {'name': _nameCtrl.text, 'email': _emailCtrl.text});
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.translate('profile_updated')), backgroundColor: AppColors.success));
      context.pop();
    } catch (_) {
      if (mounted) { final l = AppLocalizations.of(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.translate('profile_failed')), backgroundColor: AppColors.error)); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.translate('edit_profile')), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AppFormField(label: l.translate('name'), controller: _nameCtrl),
            AppFormField(label: l.translate('email'), controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _handleSave, child: Text(l.translate('save_changes')))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }
}
