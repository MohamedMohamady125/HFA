import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.userName ?? '');
    _emailController = TextEditingController(text: auth.userEmail ?? '');
  }

  Future<void> _handleSave() async {
    try {
      await ApiService().put('/coach/profile', data: {'name': _nameController.text, 'email': _emailController.text});
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully.'), backgroundColor: Colors.green));
      context.pop();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile.'), backgroundColor: Colors.red));
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
              const Text('Edit Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: _nameController, decoration: _inputDec('Name')),
              const SizedBox(height: 15),
              TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: _inputDec('Email')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(hintText: hint, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCCCCCC))));

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
