// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'https://api.habitbuilder.example.com/v1';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Habit endpoints
  static const String habits = '/habits';
  static const String habitProgress = '/habits/{id}/progress';
  static const String predefinedHabits = '/habits/predefined';

  // User endpoints
  static const String profile = '/user/profile';
}
