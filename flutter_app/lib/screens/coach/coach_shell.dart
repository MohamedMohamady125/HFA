import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'coach_home_screen.dart';
import 'coach_threads_screen.dart';
import 'coach_gear_screen.dart';
import 'coach_payments_screen.dart';
import 'coach_profile_screen.dart';

class CoachShell extends StatefulWidget {
  final Widget child;
  const CoachShell({super.key, required this.child});
  @override
  State<CoachShell> createState() => _CoachShellState();
}

class _CoachShellState extends State<CoachShell> {
  int _index = 0;

  final _screens = const [
    CoachHomeScreen(),
    CoachThreadsScreen(),
    CoachGearScreen(),
    CoachPaymentsScreen(),
    CoachProfileScreen(),
  ];

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
              onTap: () => context.go('/head-coach-branches'),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 8),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight])),
                child: Row(children: [
                  const Icon(Icons.location_city_rounded, color: Colors.white70, size: 15),
                  const SizedBox(width: 8),
                  Text(branchName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('Switch', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  const SizedBox(width: 4),
                  Icon(Icons.swap_horiz_rounded, color: Colors.white.withValues(alpha: 0.5), size: 16),
                ]),
              ),
            ),
          Expanded(child: IndexedStack(index: _index, children: _screens)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
        child: NavigationBar(
          selectedIndex: _index,
          animationDuration: const Duration(milliseconds: 300),
          onDestinationSelected: (i) => setState(() => _index = i),
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
