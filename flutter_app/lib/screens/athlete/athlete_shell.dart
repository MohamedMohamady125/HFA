import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/deep_link.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'athlete_home_screen.dart';
import 'athlete_threads_screen.dart';
import 'athlete_gear_screen.dart';
import 'athlete_profile_screen.dart';

// Allows child screens to switch tabs
class AthleteTabSwitcher extends InheritedWidget {
  final void Function(int) switchTo;
  const AthleteTabSwitcher({super.key, required this.switchTo, required super.child});

  static AthleteTabSwitcher? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AthleteTabSwitcher>();

  @override
  bool updateShouldNotify(covariant AthleteTabSwitcher oldWidget) => false;
}

class AthleteShell extends StatefulWidget {
  final Widget child;
  const AthleteShell({super.key, required this.child});
  @override
  State<AthleteShell> createState() => _AthleteShellState();
}

class _AthleteShellState extends State<AthleteShell> {
  int _index = 0;

  final _homeKey = GlobalKey<AthleteHomeScreenState>();
  final _threadsKey = GlobalKey<AthleteThreadsScreenState>();
  final _gearKey = GlobalKey<AthleteGearScreenState>();
  final _profileKey = GlobalKey<AthleteProfileScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      AthleteHomeScreen(key: _homeKey),
      AthleteThreadsScreen(key: _threadsKey),
      AthleteGearScreen(key: _gearKey),
      AthleteProfileScreen(key: _profileKey),
    ];
    DeepLink.pending.addListener(_onDeepLink);
    // Consume a deep link set before this shell mounted (cold start from a notification tap).
    WidgetsBinding.instance.addPostFrameCallback((_) => _onDeepLink());
  }

  void _onDeepLink() {
    if (!mounted) return;
    final type = DeepLink.consume();
    switch (type) {
      case 'thread': _switchTab(1);
      case 'gear': _switchTab(2);
      case 'attendance': context.push('/athlete/attendance-history');
      case null: break;
    }
  }

  @override
  void dispose() {
    DeepLink.pending.removeListener(_onDeepLink);
    super.dispose();
  }

  void _switchTab(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
    switch (i) {
      case 0: _homeKey.currentState?.silentRefresh();
      case 1: _threadsKey.currentState?.silentRefresh();
      case 2: _gearKey.currentState?.silentRefresh();
      case 3: _profileKey.currentState?.silentRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AthleteTabSwitcher(
      switchTo: _switchTab,
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: AppColors.cardBg, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))]),
          child: Builder(builder: (context) {
            final l = AppLocalizations.of(context);
            return NavigationBar(
              selectedIndex: _index,
              animationDuration: const Duration(milliseconds: 300),
              onDestinationSelected: _switchTab,
              destinations: [
                NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard_rounded), label: l.translate('home')),
                NavigationDestination(icon: const Icon(Icons.forum_outlined), selectedIcon: const Icon(Icons.forum_rounded), label: l.translate('threads_nav')),
                NavigationDestination(icon: const Icon(Icons.backpack_outlined), selectedIcon: const Icon(Icons.backpack_rounded), label: l.translate('gear')),
                NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: l.translate('profile')),
              ],
            );
          }),
        ),
      ),
    );
  }
}
