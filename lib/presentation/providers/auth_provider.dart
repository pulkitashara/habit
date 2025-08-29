import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../domain/entities/user.dart';
import '../../core/errors/failures.dart';
import '../../core/exceptions/api_exception.dart';
import '../../data/datasources/local/hive_service.dart';
import 'api_providers.dart';
import 'habit_provider.dart';

class AuthState {
  final bool isLoading;
  final User? user;
  final bool isAuthenticated;
  final String? error;
  final String? token;

  AuthState({
    this.isLoading = false,
    this.user,
    this.isAuthenticated = false,
    this.error,
    this.token,
  });

  AuthState copyWith({
    bool? isLoading,
    User? user,
    bool? isAuthenticated,
    String? error,
    String? token,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final Ref _ref;

  AuthNotifier(this._apiService, this._ref) : super(AuthState()) {

  }

  Future<void> initializeAuth() async {
    await _checkAuthStatus();
  }

  // In auth_provider.dart - Update the _checkAuthStatus method
  Future<void> _checkAuthStatus() async {
    try {
      // ✅ Ensure Hive is initialized first
      if (!HiveService.isInitialized) {
        print('❌ Hive not initialized, skipping auth check');
        state = AuthState();
        return;
      }

      final token = HiveService.getSetting('auth_token');
      final userData = HiveService.getSetting('user_data');
      final currentUserId = HiveService.getCurrentUserId();

      print('🔍 Checking auth status:');
      print('  Token exists: ${token != null}');
      print('  User data exists: ${userData != null}');
      print('  Current User ID: $currentUserId');

      // ✅ CRITICAL FIX: Check if user was properly logged out
      if (currentUserId == null || currentUserId.isEmpty) {
        print('❌ No current user - user was logged out');
        state = AuthState(); // Reset to logged out state
        return;
      }

      if (token != null && userData != null) {
        // ✅ Try to restore user from Hive first
        final savedUser = HiveService.getUser(currentUserId);

        User user;
        if (savedUser != null) {
          // Use saved user data
          user = savedUser.toEntity();
          print('✅ Restored user from Hive: ${user.username}');
        } else {
          // Fallback to session data
          user = User(
            id: userData['id'] ?? currentUserId,
            username: userData['username'] ?? 'user',
            email: userData['email'] ?? 'user@example.com',
            firstName: userData['firstName'],
            lastName: userData['lastName'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          print('✅ Created user from session data: ${user.username}');
        }

        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          token: token,
        );

        print('✅ Authentication restored successfully');
      } else {
        print('❌ No valid session found');
        state = AuthState(); // Ensure clean slate
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
      state = AuthState(); // Reset on error
    }
  }

  Future<Either<Failure, void>> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    _ref.read(apiLoadingProvider.notifier).state = true;

    try {
      final response = await _apiService.login(username, password);
      final token = response['token'];
      final userData = response['user'];
      final userId = userData['id'].toString();

      print('🔄 Starting login process for user: $userId');

      // ✅ CRITICAL: Save auth data in specific order and await each step
      await HiveService.saveSetting('auth_token', token);
      print('✅ Token saved');

      await HiveService.saveSetting('user_data', userData);
      print('✅ User data saved');

      // ✅ MOST IMPORTANT: Save current user ID and verify
      await HiveService.setCurrentUser(userId);

      // ✅ Wait a tiny bit for Hive to flush
      await Future.delayed(Duration(milliseconds: 100));

      // ✅ Verify it was actually saved
      final verifyUserId = HiveService.getCurrentUserId();
      print('🔍 Verification - User ID saved as: "$verifyUserId"');

      if (verifyUserId != userId) {
        print('❌ CRITICAL ERROR: User ID not saved properly!');
        print('  Expected: $userId');
        print('  Got: $verifyUserId');
        throw Exception('Failed to save user session');
      }

      final user = User(
        id: userId,
        username: userData['username'],
        email: userData['email'],
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save user model for offline access
      final userModel = UserModel.fromEntity(user);
      await HiveService.saveUser(userModel);
      print('✅ User model saved');

      // ✅ Update state ONLY after everything is saved
      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
        token: token,
        error: null,
      );

      print('✅ Login completed successfully');

      // Load habits after successful login
      _ref.read(habitProvider.notifier).loadHabits();

      return const Right(null);
    } catch (e) {
      print('❌ Login failed: $e');
      final errorMessage = _handleError(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
      _ref.read(apiLoadingProvider.notifier).state = false;
      _ref.read(apiErrorProvider.notifier).state = errorMessage;
      return Left(_mapExceptionToFailure(e));
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
    _ref.read(apiLoadingProvider.notifier).state = true;

    try {
      final userData = {
        'username': username,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      };

      await _apiService.signup(userData);

      state = state.copyWith(isLoading: false, error: null);
      _ref.read(apiLoadingProvider.notifier).state = false;

      return const Right(null);
    } catch (e) {
      final errorMessage = _handleError(e);

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      _ref.read(apiLoadingProvider.notifier).state = false;
      _ref.read(apiErrorProvider.notifier).state = errorMessage;

      return Left(_mapExceptionToFailure(e));
    }
  }

  // In auth_provider.dart - Fix the logout method
  Future<void> logout() async {
    final currentUser = state.user;

    if (currentUser != null) {
      // Save user data for potential future login
      final userModel = UserModel.fromEntity(currentUser);
      await HiveService.saveUser(userModel);
      print('💾 Preserved user data for: ${currentUser.username}');
    }

    // ✅ CRITICAL: Clear authentication state FIRST
    await HiveService.saveSetting('auth_token', null);
    await HiveService.saveSetting('refresh_token', null);
    await HiveService.saveSetting('user_data', null);

    // ✅ THEN logout user (this will clear current_user_id)
    await HiveService.logoutCurrentUser();

    // ✅ Reset provider state to logged out
    state = AuthState();

    // ✅ IMPORTANT: Clear habit provider state too
    _ref.read(habitProvider.notifier).clearUserData();

    print('👋 User logged out completely');
  }


  String _handleError(dynamic error) {
    if (error is AuthException) {
      return error.message;
    } else if (error is ValidationException) {
      return error.message;
    } else if (error is NetworkException) {
      return error.message;
    } else if (error is TimeoutException) {
      return error.message;
    } else if (error is ServerException) {
      return error.message;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Failure _mapExceptionToFailure(dynamic exception) {
    if (exception is AuthException) {
      return AuthFailure(exception.message);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message);
    } else if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    } else if (exception is TimeoutException) {
      return NetworkFailure(exception.message);
    } else if (exception is ServerException) {
      return ServerFailure(exception.message);
    } else {
      return ServerFailure('Unknown error occurred');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService, ref);
});
