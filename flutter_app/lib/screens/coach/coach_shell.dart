import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CoachShell extends StatelessWidget {
  final Widget child;
  const CoachShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/coach/threads')) return 1;
    if (location.startsWith('/coach/gear')) return 2;
    if (location.startsWith('/coach/profile')) return 3;
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
            case 0: context.go('/coach/home');
            case 1: context.go('/coach/threads');
            case 2: context.go('/coach/gear');
            case 3: context.go('/coach/profile');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Groups'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Gear'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
