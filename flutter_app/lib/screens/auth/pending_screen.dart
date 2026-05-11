import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hourglass_top, size: 80, color: Color(0xFF007AFF)),
                const SizedBox(height: 24),
                const Text('Pending Approval', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),
                const Text(
                  'Your registration is being reviewed by a coach. You will be notified once your account is approved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 40),
                OutlinedButton(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/guest-home');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF007AFF),
                    side: const BorderSide(color: Color(0xFF007AFF)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
