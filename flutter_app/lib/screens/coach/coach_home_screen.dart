import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

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
    final l = AppLocalizations.of(context);
    if (name.isEmpty) return const Scaffold(body: ShimmerList(count: 3));

    final isHeadCoach = context.read<AuthProvider>().role == 'head_coach';
    final tools = <Map<String, dynamic>>[
      {'title': l.translate('registration_requests'), 'icon': Icons.person_add_rounded, 'route': '/coach-manage/register-requests', 'color': AppColors.info},
      {'title': l.translate('payment_tracking'), 'icon': Icons.payments_rounded, 'route': '/coach-manage/payment', 'color': AppColors.success},
      {'title': l.translate('attendance'), 'icon': Icons.fact_check_rounded, 'route': '/coach-manage/attendance', 'color': AppColors.warning},
      if (isHeadCoach) {'title': l.translate('manage_coaches'), 'icon': Icons.people_rounded, 'route': '/head-coach-manage-coaches', 'color': AppColors.primary},
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hi, $name', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(l.translate('coach_dashboard'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                ])),
                Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.shield_rounded, color: AppColors.accent, size: 22)),
              ])),
              const SizedBox(height: 28),
              FadeSlideIn(delay: 100, child: SectionHeader(title: l.translate('quick_actions'))),
              ...tools.asMap().entries.map((e) => FadeSlideIn(
                delay: 150 + (e.key * 80),
                child: ScaleOnTap(
                  onTap: () => context.push(e.value['route'] as String),
                  child: AppCard(child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: (e.value['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(e.value['icon'] as IconData, color: e.value['color'] as Color, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(e.value['title'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                  ])),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
