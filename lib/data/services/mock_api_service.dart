import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'api_service.dart';
import '../../core/exceptions/api_exception.dart';
import '../datasources/local/hive_service.dart';

class MockApiService implements ApiService {
  final Random _random = Random();

  // ✅ Remove hardcoded users - load from Hive instead
  Map<String, Map<String, String>> _users = {};

  // Mock habits database
  Map<String, List<Map<String, dynamic>>> _userHabits = {};

  // Mock progress database
  final Map<String, List<Map<String, dynamic>>> _habitProgress = {};

  // ✅ Constructor to load users from Hive
  MockApiService() {
    _loadUsersFromHive();
  }

  // ✅ Load existing users from Hive or initialize with demo users
  void _loadUsersFromHive() {
    try {
      final savedUsers = HiveService.getSetting<Map>('mock_users');

      if (savedUsers != null && savedUsers.isNotEmpty) {
        _users = Map<String, Map<String, String>>.from(
            savedUsers.map((key, value) => MapEntry(
                key.toString(),
                Map<String, String>.from(value as Map)
            ))
        );
        print('📋 Loaded ${_users.length} users from Hive');
      } else {
        // Initialize with demo users if no saved users
        _users = {
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
        _saveUsersToHive();
      }
    } catch (e) {
      print('❌ Error loading users from Hive: $e');
      // Fallback to demo users
      _users = {
        'test@example.com': {
          'password': 'password123',
          'id': '1',
          'firstName': 'Demo',
          'lastName': 'User',
        },
      };
    }
  }

  // ✅ Save users to Hive
  Future<void> _saveUsersToHive() async {
    try {
      await HiveService.saveSetting('mock_users', _users);
      print('💾 Saved ${_users.length} users to Hive');
    } catch (e) {
      print('❌ Error saving users to Hive: $e');
    }
  }

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
      'refreshToken': 'refresh_$token',
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

    // ✅ Create new user and persist to Hive
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    _users[username] = {
      'password': password,
      'id': userId,
      'firstName': userData['firstName'] ?? 'New',
      'lastName': userData['lastName'] ?? 'User',
    };

    // ✅ Save to Hive immediately
    await _saveUsersToHive();

    print('✅ Mock API: User created successfully with ID: $userId');
    print('✅ Total users: ${_users.length}');

    return {
      'message': 'User created successfully',
      'userId': userId,
    };
  }

  // ✅ Add debug method
  void debugUsers() {
    print('=== MOCK API USERS ===');
    for (final entry in _users.entries) {
      print('Email: ${entry.key}');
      print('  ID: ${entry.value['id']}');
      print('  Name: ${entry.value['firstName']} ${entry.value['lastName']}');
    }
    print('Total users: ${_users.length}');
    print('======================');
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
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    print('🔄 Mock API: Fetching habits');

    try {
      final userId = _extractUserIdFromToken(token);
      // ✅ FIX: Use null coalescing operator instead of force unwrap
      final userHabits = _userHabits[userId] ?? [];

      print('📦 Mock API: Found ${userHabits.length} habits for user $userId');
      return List<Map<String, dynamic>>.from(userHabits);
    } catch (e) {
      print('❌ Mock API Error: $e');
      return []; // Return empty list on error
    }
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

  String _extractUserIdFromToken(String? token) {
    // ✅ FIX: Handle null token properly
    if (token == null || token.isEmpty) {
      return '1'; // Default user ID
    }

    // Extract user ID from mock token
    try {
      if (token.startsWith('mock_jwt_')) {
        final parts = token.split('_');
        if (parts.length >= 3) {
          return parts[2]; // Extract user ID from token
        }
      }

      // Fallback for other token formats
      final parts = token.split('.');
      if (parts.length >= 2) {
        final payload = utf8.decode(base64Decode(parts[1]));
        final data = json.decode(payload);
        return data['userId'] ?? 'guest_user';
      }
    } catch (e) {
      print('Token parsing error: $e');
    }

    return 'guest_user'; // Fallback
  }
}
