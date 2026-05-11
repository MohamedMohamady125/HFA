import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();

  Future<void> _handleChange() async {
    try {
      await ApiService().post('/coach/change-password', data: {
        'old_password': _currentController.text,
        'new_password': _newController.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully.'), backgroundColor: Colors.green));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to change password.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back), label: const Text('Back'), style: TextButton.styleFrom(foregroundColor: const Color(0xFF007AFF))),
              const SizedBox(height: 10),
              const Text('Change Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildInput(_currentController, 'Current Password', true),
              const SizedBox(height: 15),
              _buildInput(_newController, 'New Password', true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleChange,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController c, String hint, bool obscure) {
    return TextField(
      controller: c, obscureText: obscure,
      decoration: InputDecoration(hintText: hint, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCCC)))),
    );
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }
}
