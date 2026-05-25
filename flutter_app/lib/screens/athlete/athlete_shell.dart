import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
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
          child: NavigationBar(
            selectedIndex: _index,
            animationDuration: const Duration(milliseconds: 300),
            onDestinationSelected: _switchTab,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum_rounded), label: 'Threads'),
              NavigationDestination(icon: Icon(Icons.backpack_outlined), selectedIcon: Icon(Icons.backpack_rounded), label: 'Gear'),
              NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
