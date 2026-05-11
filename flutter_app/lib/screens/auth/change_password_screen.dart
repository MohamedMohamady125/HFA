import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();

  Future<void> _handleChange() async {
    try {
      await ApiService().post('/coach/change-password', data: {'old_password': _currentCtrl.text, 'new_password': _newCtrl.text});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully.'), backgroundColor: AppColors.success));
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to change password.'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password'), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AppFormField(label: 'CURRENT PASSWORD', controller: _currentCtrl, obscure: true),
            AppFormField(label: 'NEW PASSWORD', controller: _newCtrl, obscure: true),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _handleChange, child: const Text('Update Password'))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { _currentCtrl.dispose(); _newCtrl.dispose(); super.dispose(); }
}
