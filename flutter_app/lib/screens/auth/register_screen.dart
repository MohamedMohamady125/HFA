import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

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
    {'label': 'Maadi', 'value': '1'}, {'label': 'Hadayek Al-Ahram', 'value': '2'},
    {'label': '6th October', 'value': '3'}, {'label': 'Nasr City', 'value': '4'}, {'label': 'New Cairo', 'value': '5'},
  ];

  Future<void> _handleRegister() async {
    final l = AppLocalizations.of(context);
    if ([_nameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confirmCtrl].any((c) => c.text.isEmpty) || _selectedBranchId == null) {
      _showMsg(l.translate('fill_all_fields'), isError: true); return;
    }
    if (_passCtrl.text != _confirmCtrl.text) { _showMsg(l.translate('passwords_no_match'), isError: true); return; }

    setState(() => _loading = true);
    try {
      await ApiService().post('/auth/register', data: {
        'email': _emailCtrl.text.trim(), 'password': _passCtrl.text, 'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(), 'branch_id': int.parse(_selectedBranchId!),
      });
      if (!mounted) return;
      for (var c in [_nameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confirmCtrl]) {
        c.clear();
      }
      setState(() => _selectedBranchId = null);
      await _showSuccessDialog(l);
    } catch (e) {
      String msg = l.translate('server_error');
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['detail'] != null) msg = data['detail'].toString();
      }
      _showMsg(msg, isError: true);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _showSuccessDialog(AppLocalizations l) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
        title: Text(l.translate('successfully_registered')),
        content: Text(l.translate('registration_submitted'), textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l.translate('ok'))),
        ],
      ),
    );
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.error : AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          children: [
            Image.asset('assets/images/hfanew.png', width: 80, height: 80),
            const SizedBox(height: 16),
            Text(l.translate('create_account'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(l.translate('join_academy'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            AppCard(child: Column(children: [
              AppFormField(label: l.translate('full_name'), controller: _nameCtrl),
              AppFormField(label: l.translate('email'), controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
              AppFormField(label: l.translate('phone'), controller: _phoneCtrl, keyboardType: TextInputType.phone),
              AppFormField(label: l.translate('password'), controller: _passCtrl, obscure: true),
              AppFormField(label: l.translate('confirm_password'), controller: _confirmCtrl, obscure: true),
              Align(alignment: Alignment.centerLeft, child: Text(l.translate('branch'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                  value: _selectedBranchId, hint: Text(l.translate('select_branch'), style: const TextStyle(color: AppColors.textTertiary, fontSize: 15)),
                  isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
                  items: _branches.map((b) => DropdownMenuItem(value: b['value'], child: Text(b['label']!))).toList(),
                  onChanged: (v) => setState(() => _selectedBranchId = v),
                )),
              ),
              const SizedBox(height: 28),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _loading ? null : _handleRegister,
                child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(l.translate('submit_registration')),
              )),
            ])),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20), const SizedBox(width: 12), Expanded(child: Text(l.translate('registration_info'), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)))]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { for (var c in [_nameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confirmCtrl]) { c.dispose(); } super.dispose(); }
}
