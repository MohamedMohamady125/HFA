import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers/auth_provider.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/auth/guest_home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/admin_login_screen.dart';
import 'screens/auth/head_coach_login_screen.dart';
import 'screens/auth/pending_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/athlete/athlete_shell.dart';
import 'screens/athlete/athlete_home_screen.dart';
import 'screens/athlete/athlete_threads_screen.dart';
import 'screens/athlete/athlete_gear_screen.dart';
import 'screens/athlete/athlete_profile_screen.dart';
import 'screens/coach/coach_shell.dart';
import 'screens/coach/coach_home_screen.dart';
import 'screens/coach/coach_threads_screen.dart';
import 'screens/coach/coach_gear_screen.dart';
import 'screens/coach/coach_profile_screen.dart';
import 'screens/coach_manage/register_requests_screen.dart';
import 'screens/coach_manage/payment_screen.dart';
import 'screens/coach_manage/attendance_screen.dart';
import 'screens/coach_manage/attendance_summary_screen.dart';
import 'screens/coach/edit_profile_screen.dart';
import 'screens/coach/head_coach_branches_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _athleteShellKey = GlobalKey<NavigatorState>();
final _coachShellKey = GlobalKey<NavigatorState>();

GoRouter _createRouter(AuthProvider auth) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/guest-home',
    redirect: (context, state) {
      if (auth.loading) return null;
      final loc = state.matchedLocation;
      final publicRoutes = ['/guest-home', '/login', '/register', '/admin-login', '/head-coach-login', '/forgot-password', '/pending'];
      final isPublic = publicRoutes.any((r) => loc.startsWith(r));
      if (!auth.isLoggedIn && !isPublic) return '/guest-home';
      if (auth.isLoggedIn && !auth.isApproved && loc != '/pending') return '/pending';
      return null;
    },
    routes: [
      GoRoute(path: '/guest-home', builder: (_, __) => const GuestHomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/admin-login', builder: (_, __) => const AdminLoginScreen()),
      GoRoute(path: '/head-coach-login', builder: (_, __) => const HeadCoachLoginScreen()),
      GoRoute(path: '/pending', builder: (_, __) => const PendingScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordScreen()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/head-coach-branches', builder: (_, __) => const HeadCoachBranchesScreen()),
      GoRoute(path: '/coach-manage/register-requests', builder: (_, __) => const RegisterRequestsScreen()),
      GoRoute(path: '/coach-manage/payment', builder: (_, __) => const PaymentScreen()),
      GoRoute(path: '/coach-manage/attendance', builder: (_, __) => const AttendanceScreen()),
      GoRoute(path: '/coach-manage/summary', builder: (_, __) => const AttendanceSummaryScreen()),
      ShellRoute(
        navigatorKey: _athleteShellKey,
        builder: (_, __, child) => AthleteShell(child: child),
        routes: [
          GoRoute(path: '/athlete/home', builder: (_, __) => const AthleteHomeScreen()),
          GoRoute(path: '/athlete/threads', builder: (_, __) => const AthleteThreadsScreen()),
          GoRoute(path: '/athlete/gear', builder: (_, __) => const AthleteGearScreen()),
          GoRoute(path: '/athlete/profile', builder: (_, __) => const AthleteProfileScreen()),
        ],
      ),
      ShellRoute(
        navigatorKey: _coachShellKey,
        builder: (_, __, child) => CoachShell(child: child),
        routes: [
          GoRoute(path: '/coach/home', builder: (_, __) => const CoachHomeScreen()),
          GoRoute(path: '/coach/threads', builder: (_, __) => const CoachThreadsScreen()),
          GoRoute(path: '/coach/gear', builder: (_, __) => const CoachGearScreen()),
          GoRoute(path: '/coach/profile', builder: (_, __) => const CoachProfileScreen()),
        ],
      ),
    ],
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const HFAApp(),
    ),
  );
}

class HFAApp extends StatelessWidget {
  const HFAApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final router = _createRouter(auth);

    return MaterialApp.router(
      title: 'HFA Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
