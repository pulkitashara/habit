import 'dart:async';
import 'dart:math';
import 'api_service.dart';
import '../../core/exceptions/api_exception.dart';

class MockApiService implements ApiService {
  final Random _random = Random();

  // Mock user database
  final Map<String, Map<String, dynamic>> _users = {
    'test@example.com': {
      'password': 'password123',
      'id': '1',
      'firstName': 'Demo',
      'lastName': 'User',
    },
    'demo@habit.com': {
      'password': 'demo123',
      'id': '2',
      'firstName': 'Demo',
      'lastName': 'Tester',
    },
  };

  // Mock habits database
  final Map<String, List<Map<String, dynamic>>> _userHabits = {};

  // Mock progress database
  final Map<String, List<Map<String, dynamic>>> _habitProgress = {};

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    print('🔄 Mock API: Attempting login for $username');

    // Simulate network delay
    await _simulateNetworkDelay(1000, 2000);

    // Simulate random network errors (5% chance)
    _simulateRandomNetworkError(0.05);

    // Validate credentials
    if (username.isEmpty || password.isEmpty) {
      throw ValidationException('Username and password are required');
    }

    final user = _users[username];
    if (user == null || user['password'] != password) {
      throw AuthException('Invalid username or password');
    }

    // Generate mock JWT token
    final token = _generateMockToken(user['id']!);

    print('✅ Mock API: Login successful for $username');

    return {
      'token': token,
      'refreshToken': 'refresh_${token}',
      'user': {
        'id': user['id'],
        'username': username,
        'email': username,
        'firstName': user['firstName'],
        'lastName': user['lastName'],
      },
      'expiresIn': 3600, // 1 hour
    };
  }

  @override
  Future<Map<String, dynamic>> signup(Map<String, dynamic> userData) async {
    print('🔄 Mock API: Creating new user account');

    await _simulateNetworkDelay(1500, 2500);
    _simulateRandomNetworkError(0.03);

    final username = userData['username'] ?? userData['email'];
    final password = userData['password'];

    // Validation
    if (username == null || username.isEmpty) {
      throw ValidationException('Username/email is required');
    }

    if (password == null || password.length < 6) {
      throw ValidationException('Password must be at least 6 characters');
    }

    if (_users.containsKey(username)) {
      throw ValidationException('User already exists with this email');
    }

    // Create new user
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    _users[username] = {
      'password': password,
      'id': userId,
      'firstName': userData['firstName'] ?? 'New',
      'lastName': userData['lastName'] ?? 'User',
    };

    print('✅ Mock API: User created successfully');

    return {
      'message': 'User created successfully',
      'userId': userId,
    };
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    await _simulateNetworkDelay(500, 1000);
    _simulateRandomNetworkError(0.02);

    if (!refreshToken.startsWith('refresh_')) {
      throw AuthException('Invalid refresh token');
    }

    // Extract user ID from refresh token
    final originalToken = refreshToken.substring(8);
    final userId = _extractUserIdFromToken(originalToken);

    final newToken = _generateMockToken(userId);

    return {
      'token': newToken,
      'refreshToken': 'refresh_$newToken',
      'expiresIn': 3600,
    };
  }

  @override
  Future<void> logout(String token) async {
    await _simulateNetworkDelay(300, 800);
    print('✅ Mock API: User logged out successfully');
  }

  @override
  Future<List<Map<String, dynamic>>> getHabits(String token) async {
    print('🔄 Mock API: Fetching habits');

    await _simulateNetworkDelay(800, 1500);
    _simulateRandomNetworkError(0.08);

    final userId = _extractUserIdFromToken(token);

    // Initialize with sample habits if user has none
    // if (!_userHabits.containsKey(userId)) {
    //   _userHabits[userId] = _generateSampleHabits();
    // }

    final habits = _userHabits[userId]!;

    print('✅ Mock API: Fetched ${habits.length} habits');

    return List<Map<String, dynamic>>.from(habits);
  }

  @override
  Future<Map<String, dynamic>> createHabit(String token, Map<String, dynamic> habitData) async {
    print('🔄 Mock API: Creating new habit');

    await _simulateNetworkDelay(1000, 1800);
    _simulateRandomNetworkError(0.05);

    final userId = _extractUserIdFromToken(token);

    // Validate habit data
    if (habitData['name'] == null || habitData['name'].isEmpty) {
      throw ValidationException('Habit name is required');
    }

    // Create habit with server-assigned ID
    final habitId = 'habit_${DateTime.now().millisecondsSinceEpoch}';
    final newHabit = Map<String, dynamic>.from(habitData);
    newHabit['id'] = habitId;
    newHabit['userId'] = userId;
    newHabit['createdAt'] = DateTime.now().toIso8601String();
    newHabit['updatedAt'] = DateTime.now().toIso8601String();

    // Add to user's habits
    if (!_userHabits.containsKey(userId)) {
      _userHabits[userId] = [];
    }
    _userHabits[userId]!.add(newHabit);

    print('✅ Mock API: Habit created with ID: $habitId');

    return newHabit;
  }

  @override
  Future<Map<String, dynamic>> updateHabit(String token, String habitId, Map<String, dynamic> habitData) async {
    print('🔄 Mock API: Updating habit $habitId');

    await _simulateNetworkDelay(800, 1200);
    _simulateRandomNetworkError(0.04);

    final userId = _extractUserIdFromToken(token);
    final userHabits = _userHabits[userId] ?? [];

    final habitIndex = userHabits.indexWhere((h) => h['id'] == habitId);
    if (habitIndex == -1) {
      throw ApiException('Habit not found', 404);
    }

    // Update habit
    final updatedHabit = Map<String, dynamic>.from(userHabits[habitIndex]);
    updatedHabit.addAll(habitData);
    updatedHabit['updatedAt'] = DateTime.now().toIso8601String();

    userHabits[habitIndex] = updatedHabit;

    print('✅ Mock API: Habit updated successfully');

    return updatedHabit;
  }

  @override
  Future<void> deleteHabit(String token, String habitId) async {
    print('🔄 Mock API: Deleting habit $habitId');

    await _simulateNetworkDelay(600, 1000);
    _simulateRandomNetworkError(0.03);

    final userId = _extractUserIdFromToken(token);
    final userHabits = _userHabits[userId] ?? [];

    final habitIndex = userHabits.indexWhere((h) => h['id'] == habitId);
    if (habitIndex == -1) {
      throw ApiException('Habit not found', 404);
    }

    userHabits.removeAt(habitIndex);

    // Also remove progress data
    _habitProgress.remove(habitId);

    print('✅ Mock API: Habit deleted successfully');
  }

  @override
  Future<void> updateHabitProgress(String token, String habitId, Map<String, dynamic> progressData) async {
    print('🔄 Mock API: Updating progress for habit $habitId');

    await _simulateNetworkDelay(500, 1000);
    _simulateRandomNetworkError(0.06);

    final userId = _extractUserIdFromToken(token);

    // Verify habit exists
    final userHabits = _userHabits[userId] ?? [];
    if (!userHabits.any((h) => h['id'] == habitId)) {
      throw ApiException('Habit not found', 404);
    }

    // Add progress entry
    if (!_habitProgress.containsKey(habitId)) {
      _habitProgress[habitId] = [];
    }

    final progressEntry = Map<String, dynamic>.from(progressData);
    progressEntry['id'] = 'progress_${DateTime.now().millisecondsSinceEpoch}';
    progressEntry['habitId'] = habitId;
    progressEntry['createdAt'] = DateTime.now().toIso8601String();

    _habitProgress[habitId]!.add(progressEntry);

    print('✅ Mock API: Progress updated successfully');
  }

  @override
  Future<List<Map<String, dynamic>>> getHabitProgress(String token, String habitId) async {
    print('🔄 Mock API: Fetching progress for habit $habitId');

    await _simulateNetworkDelay(600, 1200);
    _simulateRandomNetworkError(0.05);

    final progress = _habitProgress[habitId] ?? [];

    print('✅ Mock API: Fetched ${progress.length} progress entries');

    return List<Map<String, dynamic>>.from(progress);
  }

  @override
  Future<Map<String, dynamic>> syncData(String token, Map<String, dynamic> localData) async {
    print('🔄 Mock API: Syncing local data with server');

    await _simulateNetworkDelay(2000, 4000);
    _simulateRandomNetworkError(0.1);

    // Simulate processing local changes
    final syncedItems = localData['pendingSync']?.length ?? 0;

    print('✅ Mock API: Synced $syncedItems items successfully');

    return {
      'syncedItems': syncedItems,
      'conflicts': [],
      'lastSyncTime': DateTime.now().toIso8601String(),
    };
  }

  // Helper methods
  Future<void> _simulateNetworkDelay(int minMs, int maxMs) async {
    final delay = minMs + _random.nextInt(maxMs - minMs);
    await Future.delayed(Duration(milliseconds: delay));
  }

  void _simulateRandomNetworkError(double errorProbability) {
    if (_random.nextDouble() < errorProbability) {
      final errorType = _random.nextInt(3);
      switch (errorType) {
        case 0:
          throw NetworkException('Network connection failed. Please check your internet.');
        case 1:
          throw TimeoutException();
        case 2:
          throw ServerException('Server temporarily unavailable. Please try again.');
      }
    }
  }

  String _generateMockToken(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'mock_jwt_${userId}_$timestamp';
  }

  String _extractUserIdFromToken(String token) {
    if (!token.startsWith('mock_jwt_')) {
      throw AuthException('Invalid token format');
    }

    final parts = token.split('_');
    if (parts.length < 3) {
      throw AuthException('Malformed token');
    }

    return parts[2];
  }

  // List<Map<String, dynamic>> _generateSampleHabits() {
  //   return [
  //     {
  //       'id': 'habit_sample_1',
  //       'name': 'Morning Exercise',
  //       'description': '30 minutes of exercise every morning',
  //       'category': 'fitness',
  //       'targetCount': 1,
  //       'frequency': 'daily',
  //       'createdAt': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
  //       'updatedAt': DateTime.now().toIso8601String(),
  //       'isActive': true,
  //       'color': '#FF6B6B',
  //       'icon': 'fitness_center',
  //       'currentStreak': 3,
  //       'longestStreak': 5,
  //       'completionRate': 0.7,
  //     },
  //     {
  //       'id': 'habit_sample_2',
  //       'name': 'Drink Water',
  //       'description': 'Drink 8 glasses of water daily',
  //       'category': 'nutrition',
  //       'targetCount': 8,
  //       'frequency': 'daily',
  //       'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
  //       'updatedAt': DateTime.now().toIso8601String(),
  //       'isActive': true,
  //       'color': '#4ECDC4',
  //       'icon': 'local_drink',
  //       'currentStreak': 2,
  //       'longestStreak': 4,
  //       'completionRate': 0.6,
  //     },
  //     {
  //       'id': 'habit_sample_3',
  //       'name': 'Read Books',
  //       'description': 'Read for 30 minutes daily',
  //       'category': 'productivity',
  //       'targetCount': 1,
  //       'frequency': 'daily',
  //       'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
  //       'updatedAt': DateTime.now().toIso8601String(),
  //       'isActive': true,
  //       'color': '#96CEB4',
  //       'icon': 'menu_book',
  //       'currentStreak': 1,
  //       'longestStreak': 2,
  //       'completionRate': 0.5,
  //     },
  //   ];
  // }
}
