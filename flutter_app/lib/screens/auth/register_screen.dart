import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _selectedBranchId;
  bool _loading = false;

  final _branches = [
    {'label': 'Maadi', 'value': '1'},
    {'label': 'Hadayek Al-Ahram', 'value': '2'},
    {'label': '6th October', 'value': '3'},
    {'label': 'Nasr City', 'value': '4'},
    {'label': 'New Cairo', 'value': '5'},
  ];

  Future<void> _handleRegister() async {
    if ([_nameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confirmCtrl].any((c) => c.text.isEmpty) || _selectedBranchId == null) {
      _showMsg('Please fill in all fields.', isError: true); return;
    }
    if (_passCtrl.text != _confirmCtrl.text) { _showMsg('Passwords do not match.', isError: true); return; }

    setState(() => _loading = true);
    try {
      await ApiService().post('/auth/register', data: {
        'email': _emailCtrl.text.trim(), 'password': _passCtrl.text,
        'name': _nameCtrl.text.trim(), 'phone': _phoneCtrl.text.trim(),
        'branch_id': int.parse(_selectedBranchId!),
      });
      if (!mounted) return;
      _showMsg('Registration submitted! A coach will review your request.');
    } catch (e) {
      String msg = 'Server error';
      if (e is DioException && e.response?.data != null) msg = e.response!.data['detail']?.toString() ?? msg;
      _showMsg(msg, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.error : AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          children: [
            Image.asset('assets/images/hfanew.png', width: 80, height: 80),
            const SizedBox(height: 16),
            const Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Join our swimming academy', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 32),

            AppCard(
              child: Column(
                children: [
                  AppFormField(label: 'FULL NAME', controller: _nameCtrl, hint: 'John Doe'),
                  AppFormField(label: 'EMAIL', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, hint: 'john@email.com'),
                  AppFormField(label: 'PHONE', controller: _phoneCtrl, keyboardType: TextInputType.phone, hint: '+20 xxx xxx xxxx'),
                  AppFormField(label: 'PASSWORD', controller: _passCtrl, obscure: true),
                  AppFormField(label: 'CONFIRM PASSWORD', controller: _confirmCtrl, obscure: true),
                  const Align(alignment: Alignment.centerLeft, child: Text('BRANCH', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBranchId,
                        hint: const Text('Select your branch', style: TextStyle(color: AppColors.textTertiary, fontSize: 15)),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
                        items: _branches.map((b) => DropdownMenuItem(value: b['value'], child: Text(b['label']!))).toList(),
                        onChanged: (v) => setState(() => _selectedBranchId = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleRegister,
                      child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Submit Registration'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Your registration will be reviewed by our coaching team.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { for (var c in [_nameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confirmCtrl]) c.dispose(); super.dispose(); }
}
