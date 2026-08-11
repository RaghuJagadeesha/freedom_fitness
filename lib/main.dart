import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'data/database.dart';
import 'services/auth_service.dart';
import 'services/gemini_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/morning_routine/morning_screen.dart';
import 'screens/gym/workout_screen.dart';
import 'screens/gym/exercise_detail_screen.dart';
import 'screens/gym/machine_id_screen.dart';
import 'screens/gym/repertoire_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Database.init();

  // Try silent sign-in (catches GSI FedCM errors on web gracefully)
  await AuthService.trySilentSignIn();
  // Initialize Gemini only if an API key is already stored
  await GeminiService.initialize();

  runApp(const ProviderScope(child: FreedomFitnessApp()));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = shellNavigatorKey;

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AuthService.isSignedIn ? '/home' : '/login',
  redirect: (context, state) {
    final loggedIn = AuthService.isSignedIn;
    final loggingIn = state.uri.path == '/login';
    if (!loggedIn && !loggingIn) return '/login';
    if (loggedIn && loggingIn) return '/home';
    return null;
  },
  routes: [
    // ─── Login (full-screen, no bottom nav) ───
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),

    // ─── Main app shell with bottom nav ───
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),

    // ─── Full-screen overlays ───
    GoRoute(
      path: '/morning',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MorningScreen(),
    ),
    GoRoute(
      path: '/workout',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WorkoutScreen(),
    ),
    GoRoute(
      path: '/exercise/:index',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final index = int.parse(state.pathParameters['index']!);
        return ExerciseDetailScreen(exerciseIndex: index);
      },
    ),
    GoRoute(
      path: '/machine-id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MachineIdScreen(),
    ),
    GoRoute(
      path: '/repertoire',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RepertoireScreen(),
    ),
  ],
);

class FreedomFitnessApp extends StatelessWidget {
  const FreedomFitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Freedom Fitness',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
