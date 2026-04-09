import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'data/database.dart';
import 'screens/home/home_screen.dart';
import 'screens/morning_routine/morning_screen.dart';
import 'screens/gym/workout_screen.dart';
import 'screens/gym/exercise_detail_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Database.init();
  runApp(const ProviderScope(child: FreedomFitnessApp()));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
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
