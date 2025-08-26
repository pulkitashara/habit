import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../core/errors/failures.dart';

class AuthState {
  final bool isLoading;
  final User? user;
  final bool isAuthenticated;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.user,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    User? user,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _checkAuthStatus(); // Check if already logged in
  }

  // Check if user is already logged in when app starts
  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final savedUsername = prefs.getString('username');

    if (isLoggedIn && savedUsername != null) {
      final user = User(
        id: '1',
        username: savedUsername,
        email: savedUsername,
        firstName: 'User',
        lastName: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        isAuthenticated: true,
        user: user,
      );
    }
  }

  Future<Either<Failure, void>> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // Check stored accounts or use default test account
      final prefs = await SharedPreferences.getInstance();
      final storedAccounts = prefs.getStringList('accounts') ?? ['test@example.com:password123'];

      final loginKey = '$username:$password';

      // Check if account exists
      if (storedAccounts.contains(loginKey)) {
        // Create user
        final user = User(
          id: '1',
          username: username,
          email: username,
          firstName: 'User',
          lastName: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save login state
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', username);

        state = state.copyWith(
          isLoading: false,
          user: user,
          isAuthenticated: true,
          error: null,
        );

        return const Right(null);
      } else {
        state = state.copyWith(
            isLoading: false,
            error: 'Invalid username or password'
        );
        return const Left(AuthFailure('Invalid username or password'));
      }
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: 'Login failed. Please try again.'
      );
      return const Left(AuthFailure('Login failed. Please try again.'));
    }
  }

  Future<Either<Failure, void>> signup({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.delayed(const Duration(seconds: 1));

      // Store the account
      final prefs = await SharedPreferences.getInstance();
      final storedAccounts = prefs.getStringList('accounts') ?? [];

      final accountKey = '$username:$password';
      if (!storedAccounts.contains(accountKey)) {
        storedAccounts.add(accountKey);
        await prefs.setStringList('accounts', storedAccounts);
      }

      state = state.copyWith(isLoading: false, error: null);
      return const Right(null);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: 'Signup failed. Please try again.'
      );
      return const Left(AuthFailure('Signup failed. Please try again.'));
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('username');

    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
