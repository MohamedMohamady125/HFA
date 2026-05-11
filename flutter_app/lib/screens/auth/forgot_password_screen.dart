import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FC),
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF007AFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reset Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Enter your email to receive a reset link.', style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 24),
            TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email Address',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCCC))),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset link sent!')));
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Send Reset Link', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
