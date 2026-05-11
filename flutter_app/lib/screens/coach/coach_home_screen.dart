import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});
  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  String name = '';

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final res = await ApiService().get('/users/me');
      if (mounted) setState(() => name = res.data['name'] ?? '');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load user data'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (name.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF007AFF))));
    }

    final tools = [
      {'title': '\u{1F4DD} Registration Requests', 'route': '/coach-manage/register-requests'},
      {'title': '\u{1F4B3} Payments', 'route': '/coach-manage/payment'},
      {'title': '\u{1F4CA} Attendance', 'route': '/coach-manage/attendance'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 30),
        child: Column(
          children: [
            Text('\u{1F44B} Welcome, Coach $name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text('Your coach dashboard', style: TextStyle(fontSize: 15, color: Color(0xFF666666)), textAlign: TextAlign.center),
            const SizedBox(height: 25),
            Wrap(
              spacing: 16, runSpacing: 16,
              children: tools.map((tool) => SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push(tool['route']!),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(tool['title']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333)), textAlign: TextAlign.center),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
