import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'athlete_home_screen.dart';
import 'athlete_threads_screen.dart';
import 'athlete_gear_screen.dart';
import 'athlete_profile_screen.dart';

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

  void _onTabSelected(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    // Silent background refresh when switching to a tab
    switch (i) {
      case 0: _homeKey.currentState?.silentRefresh();
      case 1: _threadsKey.currentState?.silentRefresh();
      case 2: _gearKey.currentState?.silentRefresh();
      case 3: _profileKey.currentState?.silentRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
        child: NavigationBar(
          selectedIndex: _index,
          animationDuration: const Duration(milliseconds: 300),
          onDestinationSelected: _onTabSelected,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum_rounded), label: 'Threads'),
            NavigationDestination(icon: Icon(Icons.backpack_outlined), selectedIcon: Icon(Icons.backpack_rounded), label: 'Gear'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
