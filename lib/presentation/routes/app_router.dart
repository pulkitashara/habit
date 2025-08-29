import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/hive_service.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/habit/habit_detail_screen.dart';
import '../screens/habit/create_habit_screen.dart';
import '../providers/auth_provider.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

// ✅ Create a router provider that watches authentication state
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.fullPath == RouteNames.login ||
          state.fullPath == RouteNames.signup;
      final isSplashRoute = state.fullPath == RouteNames.splash;

      print('🛣️ Router redirect check:');
      print('  Current path: ${state.fullPath}');
      print('  Is authenticated: $isAuthenticated');

      // Always allow splash screen
      if (isSplashRoute) return null;

      // ✅ Double check with HiveService
      final currentUserId = HiveService.getCurrentUserId();
      final isReallyAuthenticated = isAuthenticated &&
          currentUserId != null &&
          currentUserId.isNotEmpty;

      print('  Current user ID: $currentUserId');
      print('  Really authenticated: $isReallyAuthenticated');

      // If not authenticated, redirect to login (except for auth routes)
      if (!isReallyAuthenticated && !isAuthRoute) {
        print('🔄 Redirecting to login - not authenticated');
        return RouteNames.login;
      }

      // If authenticated and on auth route, redirect to dashboard
      if (isReallyAuthenticated && isAuthRoute) {
        print('🔄 Redirecting to dashboard - already authenticated');
        return RouteNames.dashboard;
      }

      return null;
    },


    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      // GoRoute(
      //   path: RouteNames.createHabit,
      //   builder: (context, state) => const CreateHabitScreen(),
      // ),
      GoRoute(
        path: '${RouteNames.habitDetail}/:habitId',
        builder: (context, state) {
          final habitId = state.pathParameters['habitId']!;
          return HabitDetailScreen(habitId: habitId);
        },
      ),

      GoRoute(
        path: '/add-habit',
        builder: (context, state) => const AddHabitScreen(),
      ),

    ],
  );
});

// ✅ Legacy AppRouter class (kept for compatibility, but not used)
class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      // GoRoute(
      //   path: RouteNames.createHabit,
      //   builder: (context, state) => const CreateHabitScreen(),
      // ),
      GoRoute(
        path: '${RouteNames.habitDetail}/:habitId',
        builder: (context, state) {
          final habitId = state.pathParameters['habitId']!;
          return HabitDetailScreen(habitId: habitId);
        },
      ),
    ],
  );
}
