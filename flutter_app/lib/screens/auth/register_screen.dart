import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
    if (_nameController.text.isEmpty || _emailController.text.isEmpty ||
        _phoneController.text.isEmpty || _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty || _selectedBranchId == null) {
      _showMessage('Please fill in all fields.', isError: true);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService().post('/auth/register', data: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'branch_id': int.parse(_selectedBranchId!),
      });
      if (!mounted) return;
      _showMessage('Your request will be reviewed by a coach.');
    } catch (e) {
      String msg = 'Server error';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        msg = data['detail']?.toString() ?? data['message']?.toString() ?? msg;
      }
      _showMessage(msg, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
              child: Center(
                child: Column(
                  children: [
                    Image.asset('assets/images/hfanew.png', width: 120, height: 120),
                    const SizedBox(height: 12),
                    const Text('Join Our Academy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    const Text('Create your athlete account', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    const SizedBox(height: 32),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
                        boxShadow: [BoxShadow(color: const Color(0xFF0EA5E9).withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField('Full Name', _nameController),
                          _buildField('Email Address', _emailController, keyboardType: TextInputType.emailAddress),
                          _buildField('Phone Number', _phoneController, keyboardType: TextInputType.phone),
                          _buildField('Password', _passwordController, obscure: true),
                          _buildField('Confirm Password', _confirmPasswordController, obscure: true),
                          const Text('Select Branch', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBranchId,
                                hint: const Text('Select your branch', style: TextStyle(color: Color(0xFF94A3B8))),
                                isExpanded: true,
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _loading ? const Color(0xFF94A3B8) : const Color(0xFF00D4FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(_loading ? 'Submitting...' : 'Submit Request', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                            child: const Text(
                              'Your registration will be reviewed by our coaching team. You\'ll receive a confirmation email once approved.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16, left: 20,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF475569)),
                style: IconButton.styleFrom(backgroundColor: Colors.white, elevation: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {TextInputType? keyboardType, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: 'Enter your ${label.toLowerCase()}',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
