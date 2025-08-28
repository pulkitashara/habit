import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import '../../data/services/api_service.dart';
import '../../domain/entities/user.dart';
import '../../core/errors/failures.dart';
import '../../core/exceptions/api_exception.dart';
import '../../data/datasources/local/hive_service.dart';
import 'api_providers.dart';

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
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = HiveService.getSetting<String>('auth_token');
    final userData = HiveService.getSetting<Map>('user_data');

    if (token != null && userData != null) {
      final user = User(
        id: userData['id'] ?? '1',
        username: userData['username'] ?? 'user',
        email: userData['email'] ?? 'user@example.com',
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        token: token,
      );
    }
  }

  Future<Either<Failure, void>> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    _ref.read(apiLoadingProvider.notifier).state = true;

    try {
      // Call mock API
      final response = await _apiService.login(username, password);

      // Extract data from response
      final token = response['token'];
      final userData = response['user'];

      // Store auth data
      await HiveService.saveSetting('auth_token', token);
      await HiveService.saveSetting('refresh_token', response['refreshToken']);
      await HiveService.saveSetting('user_data', userData);

      // Create user entity
      final user = User(
        id: userData['id'],
        username: userData['username'],
        email: userData['email'],
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await HiveService.setCurrentUser(user.id);


      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
        token: token,
        error: null,
      );

      _ref.read(apiLoadingProvider.notifier).state = false;
      _ref.read(apiErrorProvider.notifier).state = null;

      return const Right(null);
    } catch (e) {
      // Handle error
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

  Future<void> logout() async {
    final currentUserId = HiveService.getCurrentUserId();

    if (currentUserId != null) {
      // ✅ Clear data for current user
      await HiveService.clearDataForUser(currentUserId);
    }

    // Clear authentication data
    await HiveService.saveSetting('auth_token', null);
    await HiveService.saveSetting('refresh_token', null);
    await HiveService.saveSetting('user_data', null);
    await HiveService.setCurrentUser('');

    state = AuthState();
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
