import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AthleteShell extends StatelessWidget {
  final Widget child;
  const AthleteShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/athlete/threads')) return 1;
    if (location.startsWith('/athlete/gear')) return 2;
    if (location.startsWith('/athlete/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/athlete/home');
            case 1: context.go('/athlete/threads');
            case 2: context.go('/athlete/gear');
            case 3: context.go('/athlete/profile');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Threads'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Gear'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
