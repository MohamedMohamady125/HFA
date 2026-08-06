import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/deep_link.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'coach_home_screen.dart';
import 'coach_threads_screen.dart';
import 'coach_gear_screen.dart';
import 'coach_athletes_screen.dart';
import 'coach_profile_screen.dart';

class CoachShell extends StatefulWidget {
  final Widget child;
  const CoachShell({super.key, required this.child});
  @override
  State<CoachShell> createState() => _CoachShellState();
}

class _CoachShellState extends State<CoachShell> {
  int _index = 0;

  final _homeKey = GlobalKey<CoachHomeScreenState>();
  final _threadsKey = GlobalKey<CoachThreadsScreenState>();
  final _gearKey = GlobalKey<CoachGearScreenState>();
  final _athletesKey = GlobalKey<CoachAthletesScreenState>();
  final _profileKey = GlobalKey<CoachProfileScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CoachHomeScreen(key: _homeKey),
      CoachThreadsScreen(key: _threadsKey),
      CoachGearScreen(key: _gearKey),
      CoachAthletesScreen(key: _athletesKey),
      CoachProfileScreen(key: _profileKey),
    ];
    DeepLink.pending.addListener(_onDeepLink);
    // Consume a deep link set before this shell mounted (cold start from a notification tap).
    WidgetsBinding.instance.addPostFrameCallback((_) => _onDeepLink());
  }

  void _onDeepLink() {
    if (!mounted) return;
    final type = DeepLink.consume();
    switch (type) {
      case 'thread': _onTabSelected(1);
      case 'gear': _onTabSelected(2);
      case 'attendance': _onTabSelected(3);
      case null: break;
    }
  }

  @override
  void dispose() {
    DeepLink.pending.removeListener(_onDeepLink);
    super.dispose();
  }

  void _onTabSelected(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
    switch (i) {
      case 0: _homeKey.currentState?.silentRefresh();
      case 1: _threadsKey.currentState?.silentRefresh();
      case 2: _gearKey.currentState?.silentRefresh();
      case 3: _athletesKey.currentState?.silentRefresh();
      case 4: _profileKey.currentState?.silentRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isHC = auth.role == 'head_coach';
    final branchName = auth.user?['branch_name'];

    return Scaffold(
      body: Column(
        children: [
          if (isHC && branchName != null)
            GestureDetector(
              onTap: () { HapticFeedback.lightImpact(); context.go('/head-coach-branches'); },
              child: Container(
                width: double.infinity,
                padding: EdgeInsetsDirectional.fromSTEB(16, MediaQuery.of(context).padding.top + 8, 16, 10),
                decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.location_city_rounded, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Text(branchName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0)),
                  const Spacer(),
                  Text(AppLocalizations.of(context).translate('switch_text'), style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(Icons.swap_horiz_rounded, color: Colors.white.withValues(alpha: 0.6), size: 16),
                ]),
              ),
            ),
          Expanded(
            child: (isHC && branchName != null)
                ? MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: IndexedStack(index: _index, children: _screens),
                  )
                : IndexedStack(index: _index, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: AppColors.cardBg, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))]),
        child: Builder(builder: (context) {
          final l = AppLocalizations.of(context);
          return NavigationBar(
            selectedIndex: _index,
            animationDuration: const Duration(milliseconds: 300),
            onDestinationSelected: _onTabSelected,
            destinations: [
              NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard_rounded), label: l.translate('home')),
              NavigationDestination(icon: const Icon(Icons.forum_outlined), selectedIcon: const Icon(Icons.forum_rounded), label: l.translate('chat')),
              NavigationDestination(icon: const Icon(Icons.backpack_outlined), selectedIcon: const Icon(Icons.backpack_rounded), label: l.translate('gear')),
              NavigationDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups_rounded), label: l.translate('athletes')),
              NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: l.translate('profile')),
            ],
          );
        }),
      ),
    );
  }
}
