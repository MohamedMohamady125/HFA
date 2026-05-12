import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
    final auth = context.watch<AuthProvider>();
    final isHeadCoach = auth.role == 'head_coach';
    final branchName = auth.user?['branch_name'];

    return Scaffold(
      body: Column(
        children: [
          // Branch banner for head coach
          if (isHeadCoach && branchName != null)
            GestureDetector(
              onTap: () => context.go('/head-coach-branches'),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 8),
                color: AppColors.primary,
                child: Row(
                  children: [
                    const Icon(Icons.location_city_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(branchName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.go('/head-coach-manage-coaches'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.people_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Coaches', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.swap_horiz_rounded, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          Expanded(child: child),
        ],
      ),
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
