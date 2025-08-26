import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    // ✅ Add redirect logic based on authentication
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.fullPath == RouteNames.login ||
          state.fullPath == RouteNames.signup;
      final isSplashRoute = state.fullPath == RouteNames.splash;

      // Allow splash screen
      if (isSplashRoute) return null;

      // If not authenticated, redirect to login (except for auth routes)
      if (!isAuthenticated && !isAuthRoute) {
        return RouteNames.login;
      }

      // If authenticated and on auth route, redirect to dashboard
      if (isAuthenticated && isAuthRoute) {
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
      GoRoute(
        path: RouteNames.createHabit,
        builder: (context, state) => const CreateHabitScreen(),
      ),
      GoRoute(
        path: '${RouteNames.habitDetail}/:habitId',
        builder: (context, state) {
          final habitId = state.pathParameters['habitId']!;
          return HabitDetailScreen(habitId: habitId);
        },
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
      GoRoute(
        path: RouteNames.createHabit,
        builder: (context, state) => const CreateHabitScreen(),
      ),
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
