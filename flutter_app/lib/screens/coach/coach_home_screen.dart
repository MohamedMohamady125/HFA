import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});
  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  String name = '';

  @override
  void initState() { super.initState(); _fetchUser(); }

  Future<void> _fetchUser() async {
    try { final res = await ApiService().get('/users/me'); if (mounted) setState(() => name = res.data['name'] ?? ''); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (name.isEmpty) return const AppLoadingScreen(message: 'Loading...');

    final tools = [
      {'title': 'Registration Requests', 'icon': Icons.person_add_rounded, 'route': '/coach-manage/register-requests', 'color': AppColors.info},
      {'title': 'Payment Tracking', 'icon': Icons.payments_rounded, 'route': '/coach-manage/payment', 'color': AppColors.success},
      {'title': 'Attendance', 'icon': Icons.fact_check_rounded, 'route': '/coach-manage/attendance', 'color': AppColors.warning},
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Hi, $name', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      const Text('Coach Dashboard', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                    ]),
                  ),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.shield_rounded, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const SectionHeader(title: 'Quick Actions'),
              ...tools.map((tool) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => context.push(tool['route'] as String),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: (tool['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(tool['icon'] as IconData, color: tool['color'] as Color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Text(tool['title'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
