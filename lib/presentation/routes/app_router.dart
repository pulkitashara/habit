import 'dart:async';

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

class AppRouter {
  static GoRouter router(WidgetRef ref) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: RouteNames.splash,
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final isAuthenticated = authState.isAuthenticated;

        // Allow splash screen
        if (state.fullPath == RouteNames.splash) {
          return null;
        }

        // Handle auth redirects
        final isAuthRoute = state.fullPath == RouteNames.login ||
            state.fullPath == RouteNames.signup;

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
      refreshListenable: // ✅ ADD THIS - Listen to auth changes
      StreamNotifier(() => ref.read(authProvider.notifier).stream),
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
}

// Helper class to make GoRouter reactive to Riverpod
class StreamNotifier extends ChangeNotifier {
  StreamNotifier(Stream Function() streamProvider) {
    _subscription = streamProvider().listen((_) => notifyListeners());
  }

  late final StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
