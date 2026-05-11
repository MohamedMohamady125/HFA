import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class CoachShell extends StatelessWidget {
  final Widget child;
  const CoachShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/coach/threads')) return 1;
    if (loc.startsWith('/coach/gear')) return 2;
    if (loc.startsWith('/coach/payments')) return 3;
    if (loc.startsWith('/coach/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
        child: NavigationBar(
          selectedIndex: _currentIndex(context),
          onDestinationSelected: (i) {
            switch (i) {
              case 0: context.go('/coach/home');
              case 1: context.go('/coach/threads');
              case 2: context.go('/coach/gear');
              case 3: context.go('/coach/payments');
              case 4: context.go('/coach/profile');
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum_rounded), label: 'Chat'),
            NavigationDestination(icon: Icon(Icons.backpack_outlined), selectedIcon: Icon(Icons.backpack_rounded), label: 'Gear'),
            NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments_rounded), label: 'Payments'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
