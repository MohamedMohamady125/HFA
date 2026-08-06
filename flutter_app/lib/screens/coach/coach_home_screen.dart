import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/offline/offline_repository.dart';
import '../../services/refresh_bus.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});
  @override
  State<CoachHomeScreen> createState() => CoachHomeScreenState();
}

class CoachHomeScreenState extends State<CoachHomeScreen> with LiveRefreshMixin {
  String name = '';

  void silentRefresh() { _fetchUser(); }

  @override
  void onLiveRefresh() { _fetchUser(); }

  @override
  void initState() {
    super.initState();
    // Sync cache read - instant, no shimmer
    final cached = OfflineRepository.getCached('/users/me');
    if (cached is Map) name = cached['name']?.toString() ?? '';
    // Offline with no cache: fall back to the logged-in user so the
    // dashboard still renders instead of an endless shimmer.
    if (name.isEmpty) name = context.read<AuthProvider>().userName ?? '';
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try { final data = await OfflineRepository.getUserMe(); if (mounted) setState(() => name = data['name'] ?? ''); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (name.isEmpty) return const Scaffold(body: ShimmerList(count: 3));

    final auth = context.read<AuthProvider>();
    final isHeadCoach = auth.role == 'head_coach';
    final branchName = auth.user?['branch_name']?.toString() ?? '';
    final tools = <Map<String, dynamic>>[
      {'title': l.translate('registration_requests'), 'icon': Icons.person_add_rounded, 'route': '/coach-manage/register-requests', 'color': AppColors.info},
      {'title': l.translate('payment_tracking'), 'icon': Icons.payments_rounded, 'route': '/coach-manage/payment', 'color': AppColors.success},
      {'title': l.translate('attendance'), 'icon': Icons.fact_check_rounded, 'route': '/coach-manage/attendance', 'color': AppColors.warning},
      if (isHeadCoach) {'title': l.translate('manage_coaches'), 'icon': Icons.people_rounded, 'route': '/head-coach-manage-coaches', 'color': AppColors.primary},
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            FadeSlideIn(
              child: HeroHeader(
                title: '${l.translate('hi')}, $name',
                subtitle: branchName.isNotEmpty ? branchName : l.translate('coach_dashboard'),
                trailing: GradientAvatar(name: name, size: 46),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(delay: 50, child: SectionHeader(title: l.translate('quick_actions'))),
                    ...tools.asMap().entries.map((e) => FadeSlideIn(
                      delay: 100 + (e.key * 50),
                      child: ActionTile(
                        icon: e.value['icon'] as IconData,
                        title: e.value['title'] as String,
                        color: e.value['color'] as Color,
                        onTap: () => context.push(e.value['route'] as String),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
