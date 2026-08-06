import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

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
import 'screens/auth/parent_code_screen.dart';
import 'screens/athlete/athlete_shell.dart';
import 'screens/coach/coach_shell.dart';
import 'screens/coach_manage/register_requests_screen.dart';
import 'screens/coach_manage/payment_screen.dart';
import 'screens/coach_manage/attendance_screen.dart';
import 'screens/coach_manage/attendance_summary_screen.dart';
import 'screens/coach/edit_profile_screen.dart';
import 'screens/coach/head_coach_branches_screen.dart';
import 'screens/coach/manage_coaches_screen.dart';
import 'screens/coach/manage_branches_screen.dart';
import 'screens/athlete/athlete_attendance_screen.dart';
import 'screens/athlete/notifications_screen.dart';
import 'screens/auth/branches_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/offline/hive_cache.dart';
import 'services/offline/sync_queue.dart';
import 'services/offline/connectivity_service.dart';
import 'services/push_notification_service.dart';
import 'services/refresh_bus.dart';
import 'widgets/offline_status_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  // Keep the system status bar visible (time, battery, network indicators)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // Initialize date formatting for Arabic
  await initializeDateFormatting('ar');

  // Initialize Firebase (mobile only - no web config)
  if (!kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await PushNotificationService.init();
  }

  // Initialize offline layer
  await HiveCache.init();
  await SyncQueue.init();
  await ConnectivityService.init();

  final authProvider = AuthProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: HFAApp(authProvider: authProvider),
    ),
  );
}

class HFAApp extends StatefulWidget {
  final AuthProvider authProvider;
  const HFAApp({super.key, required this.authProvider});

  @override
  State<HFAApp> createState() => _HFAAppState();
}

class _HFAAppState extends State<HFAApp> with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app is a good moment to retry queued offline writes
    // and refresh whatever screen is currently visible.
    if (state == AppLifecycleState.resumed) {
      ConnectivityService.recheckAndFlush();
      RefreshBus.notify();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/guest-home',
      refreshListenable: widget.authProvider,
      redirect: (context, state) {
        final auth = widget.authProvider;
        if (auth.loading) return null;
        final loc = state.matchedLocation;

        final guestOnly = ['/guest-home', '/login', '/register', '/admin-login', '/head-coach-login', '/parent-code', '/branches'];
        final isGuestOnly = guestOnly.any((r) => loc.startsWith(r));

        if (!auth.isLoggedIn) {
          // Forgot-password is public: reachable by guests and logged-in users alike.
          return (isGuestOnly || loc.startsWith('/forgot-password')) ? null : '/guest-home';
        }

        if (!auth.isApproved && loc != '/pending') return '/pending';

        // Head-coach-only screens: block non-head-coach users.
        const headCoachOnly = ['/head-coach-branches', '/head-coach-manage-coaches', '/head-coach-manage-branches'];
        if (headCoachOnly.contains(loc) && auth.role != 'head_coach') {
          return auth.role == 'coach' ? '/coach/home' : '/athlete/home';
        }

        if (isGuestOnly) {
          if (auth.role == 'head_coach') return '/head-coach-branches';
          if (auth.role == 'coach') return '/coach/home';
          return '/athlete/home';
        }

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
        GoRoute(path: '/parent-code', builder: (_, __) => const ParentCodeScreen()),
        GoRoute(path: '/branches', builder: (_, __) => const BranchesScreen()),
        GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordScreen()),
        GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
        GoRoute(path: '/head-coach-branches', builder: (_, __) => const HeadCoachBranchesScreen()),
        GoRoute(path: '/head-coach-manage-coaches', builder: (_, __) => const ManageCoachesScreen()),
        GoRoute(path: '/head-coach-manage-branches', builder: (_, __) => const ManageBranchesScreen()),
        GoRoute(path: '/coach-manage/register-requests', builder: (_, __) => const RegisterRequestsScreen()),
        GoRoute(path: '/coach-manage/payment', builder: (_, __) => const PaymentScreen()),
        GoRoute(path: '/coach-manage/attendance', builder: (_, __) => const AttendanceScreen()),
        GoRoute(path: '/coach-manage/summary', builder: (_, __) => const AttendanceSummaryScreen()),
        GoRoute(path: '/athlete/attendance-history', builder: (_, __) => const AthleteAttendanceScreen()),
        GoRoute(path: '/athlete/notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/athlete/home', builder: (_, __) => const AthleteShell(child: SizedBox())),
        GoRoute(path: '/coach/home', builder: (_, __) => const CoachShell(child: SizedBox())),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp.router(
      title: 'HFA Fitness',
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
      builder: (context, child) => OfflineStatusBar(child: child ?? const SizedBox.shrink()),
      routerConfig: _router,
    ));
  }
}
