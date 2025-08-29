// lib/data/datasources/local/hive_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/habit_model.dart';
import '../../models/habit_progress_model.dart';
import '../../models/user_model.dart';

class HiveService {
  static const String _habitsBox = 'habits';
  static const String _progressBox = 'progress';
  static const String _settingsBox = 'settings';
  static const String _usersBox = 'users'; // ✅ Add users box
  static bool _isInitialized = false;

  static Future<void> initializeHive() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    Hive.registerAdapter(HabitModelAdapter());
    Hive.registerAdapter(HabitProgressModelAdapter());
    Hive.registerAdapter(UserModelAdapter());

    // ✅ Open boxes and verify
    await Hive.openBox<HabitModel>(_habitsBox);
    await Hive.openBox<HabitProgressModel>(_progressBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox<UserModel>(_usersBox);

    _isInitialized = true;

    // ✅ Verify boxes are working
    print('✅ Hive initialized successfully');
    print('  Habits box: ${Hive.isBoxOpen(_habitsBox)}');
    print('  Progress box: ${Hive.isBoxOpen(_progressBox)}');
    print('  Settings box: ${Hive.isBoxOpen(_settingsBox)}');
    print('  Users box: ${Hive.isBoxOpen(_usersBox)}');
  }


  static Box<HabitModel> get _habitsBoxInstance => Hive.box<HabitModel>(_habitsBox);
  static Box<HabitProgressModel> get _progressBoxInstance => Hive.box<HabitProgressModel>(_progressBox);
  static Box get _settingsBoxInstance => Hive.box(_settingsBox);
  static Box<UserModel> get _usersBoxInstance => Hive.box<UserModel>(_usersBox); // ✅ Add users box getter

  // ✅ Enhanced User Management
  static Future<void> setCurrentUser(String userId) async {
    try {
      print('🔄 Setting current user: $userId');

      // ✅ Clear any existing value first
      await _settingsBoxInstance.delete('current_user_id');
      await _settingsBoxInstance.flush();

      // ✅ Set new value
      await _settingsBoxInstance.put('current_user_id', userId);
      await _settingsBoxInstance.flush();

      // ✅ Verify it was saved
      final saved = _settingsBoxInstance.get('current_user_id');
      print('✅ User ID set and verified: "$saved"');

      if (saved?.toString() != userId) {
        throw Exception('Failed to save current user ID');
      }
    } catch (e) {
      print('❌ Error setting current user: $e');
      rethrow;
    }
  }

  static String? getCurrentUserId() {
    try {
      final userId = _settingsBoxInstance.get('current_user_id');
      // ✅ Handle null and convert to string properly
      if (userId == null) {
        return null;
      }
      final userIdStr = userId.toString();
      return userIdStr.isEmpty ? null : userIdStr;
    } catch (e) {
      print('❌ Error getting current user ID: $e');
      return null;
    }
  }


  // ✅ Save user data for offline access
  static Future<void> saveUser(UserModel user) async {
    await _usersBoxInstance.put(user.id, user);
    print('💾 Saved user: ${user.username} (${user.id})');
  }

  // ✅ Get user data
  static UserModel? getUser(String userId) {
    return _usersBoxInstance.get(userId);
  }

  // ✅ Get all stored users (for user switching)
  static List<UserModel> getAllUsers() {
    return _usersBoxInstance.values.toList();
  }

  static void debugBoxContents() {
    print('=== HIVE BOX DEBUG ===');
    try {
      final settingsBox = _settingsBoxInstance;
      print('Settings Box Keys: ${settingsBox.keys.toList()}');

      for (final key in settingsBox.keys) {
        final value = settingsBox.get(key);
        print('  $key: $value (${value.runtimeType})');
      }

      print('Direct current_user_id check: ${settingsBox.get('current_user_id')}');
      print('getCurrentUserId() result: "${getCurrentUserId()}"');
    } catch (e) {
      print('❌ Error reading box contents: $e');
    }
    print('====================');
  }


  // ✅ Filter habits by current user with better error handling
  static List<HabitModel> getAllHabits() {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null || currentUserId.isEmpty) {
      print('⚠️ No current user ID found');
      return [];
    }

    final userHabits = _habitsBoxInstance.values
        .where((habit) => habit.userId == currentUserId)
        .toList();

    print('📊 Found ${userHabits.length} habits for user $currentUserId');
    return userHabits;
  }

  static Future<void> saveHabit(HabitModel habit) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      print('❌ Cannot save habit: No current user');
      return;
    }

    // ✅ Ensure habit belongs to current user
    final habitWithUser = habit.copyWith(userId: currentUserId);
    await _habitsBoxInstance.put(habit.id, habitWithUser);
    print('💾 Saved habit: ${habit.name} for user $currentUserId');
  }

  static HabitModel? getHabit(String habitId) {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return null;

    final habit = _habitsBoxInstance.get(habitId);
    if (habit?.userId != currentUserId) {
      print('⚠️ Habit $habitId does not belong to current user $currentUserId');
      return null;
    }
    return habit;
  }

  static Future<void> deleteHabit(String habitId) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return;

    // ✅ Verify ownership before deletion
    final habit = _habitsBoxInstance.get(habitId);
    if (habit?.userId != currentUserId) {
      print('⚠️ Cannot delete habit: not owned by current user');
      return;
    }

    await _habitsBoxInstance.delete(habitId);

    // Delete associated progress
    final progressToDelete = _progressBoxInstance.values
        .where((progress) => progress.habitId == habitId && progress.userId == currentUserId)
        .map((progress) => progress.key)
        .toList();

    await _progressBoxInstance.deleteAll(progressToDelete);
    print('🗑️ Deleted habit $habitId and ${progressToDelete.length} progress entries');
  }

  // ✅ Enhanced progress operations with user filtering
  static Future<void> saveProgress(HabitProgressModel progress) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return;

    // ✅ Ensure progress belongs to current user
    final progressWithUser = HabitProgressModel(
      id: progress.id,
      habitId: progress.habitId,
      date: progress.date,
      completed: progress.completed,
      target: progress.target,
      isCompleted: progress.isCompleted,
      notes: progress.notes,
      createdAt: progress.createdAt,
      synced: progress.synced,
      userId: currentUserId,
    );

    final dateKey = '${progress.habitId}_${_getDateKey(progress.date)}_$currentUserId';
    await _progressBoxInstance.put(dateKey, progressWithUser);
    print('💾 Saved progress for habit ${progress.habitId} on ${progress.date.day}/${progress.date.month}');
  }

  static List<HabitProgressModel> getHabitProgress(String habitId) {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return [];

    return _progressBoxInstance.values
        .where((progress) =>
    progress.habitId == habitId &&
        progress.userId == currentUserId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static HabitProgressModel? getTodayProgress(String habitId) {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return null;

    final today = DateTime.now();
    final todayKey = '${habitId}_${_getDateKey(today)}_$currentUserId';
    return _progressBoxInstance.get(todayKey);
  }

  static HabitProgressModel? getProgressForDate(String habitId, DateTime date) {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return null;

    final dateKey = '${habitId}_${_getDateKey(date)}_$currentUserId';
    return _progressBoxInstance.get(dateKey);
  }

  // ✅ Calculate streak for current user only (unchanged but verified)
  static int calculateCurrentStreak(String habitId) {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return 0;

    final allProgress = getHabitProgress(habitId)
        .where((p) => p.isCompleted)
        .toList();

    if (allProgress.isEmpty) return 0;

    allProgress.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final progress = getProgressForDate(habitId, checkDate);
      if (progress?.isCompleted == true) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (i == 0) {
        // Skip today if not completed yet
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
    }

    return streak;
  }

  static double calculateCompletionRate(String habitId) {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return 0.0;

    final habit = getHabit(habitId);
    if (habit == null) return 0.0;

    final daysSinceCreation = DateTime.now().difference(habit.createdAt).inDays + 1;
    final completedDays = getHabitProgress(habitId)
        .where((p) => p.isCompleted)
        .length;

    return daysSinceCreation > 0 ? completedDays / daysSinceCreation : 0.0;
  }

  // ✅ FIXED: Don't delete user data on logout - just switch user
  static Future<void> logoutCurrentUser() async {
    try {
      print('🔄 Logging out current user (preserving data)');

      // ✅ Delete the key completely instead of setting to empty
      await _settingsBoxInstance.delete('current_user_id');

      // ✅ Force flush to disk
      await _settingsBoxInstance.flush();

      // ✅ Verify it was deleted
      final remaining = _settingsBoxInstance.get('current_user_id');
      print('✅ Verified user ID cleared: $remaining');
    } catch (e) {
      print('❌ Error logging out user: $e');
    }
  }




  // ✅ Optional: Method to permanently delete a user's data (use carefully)
  static Future<void> permanentlyDeleteUser(String userId) async {
    print('🗑️ Permanently deleting all data for user: $userId');

    // Delete user's habits
    final habitsToDelete = _habitsBoxInstance.values
        .where((habit) => habit.userId == userId)
        .map((habit) => habit.key)
        .toList();
    await _habitsBoxInstance.deleteAll(habitsToDelete);

    // Delete user's progress
    final progressToDelete = _progressBoxInstance.values
        .where((progress) => progress.userId == userId)
        .map((progress) => progress.key)
        .toList();
    await _progressBoxInstance.deleteAll(progressToDelete);

    // Delete user record
    await _usersBoxInstance.delete(userId);

    print('🗑️ Deleted ${habitsToDelete.length} habits and ${progressToDelete.length} progress entries for user $userId');
  }

  // ✅ Enhanced settings with user context
  static Future<void> saveSetting<T>(String key, T value) async {
    final currentUserId = getCurrentUserId();
    final userKey = currentUserId != null ? '${key}_$currentUserId' : key;
    await _settingsBoxInstance.put(userKey, value);
  }

  static T? getSetting<T>(String key) {
    final currentUserId = getCurrentUserId();
    final userKey = currentUserId != null ? '${key}_$currentUserId' : key;
    return _settingsBoxInstance.get(userKey) ?? _settingsBoxInstance.get(key); // Fallback to global
  }

  static String _getDateKey(DateTime date) {
    return '${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}';
  }

  static bool get isInitialized {
    try {
      return Hive.isBoxOpen('habits') &&
          Hive.isBoxOpen('progress') &&
          Hive.isBoxOpen('users');
    } catch (e) {
      return false;
    }
  }

  // ✅ Enhanced debug info
  static void debugPrintStorage() {
    final currentUserId = getCurrentUserId();
    print('=== HIVE DEBUG INFO ===');
    print('Current User ID: $currentUserId');
    print('All Users: ${getAllUsers().map((u) => '${u.username} (${u.id})').join(', ')}');
    print('Habits count (current user): ${getAllHabits().length}');
    print('Total habits count: ${_habitsBoxInstance.length}');
    print('Total progress count: ${_progressBoxInstance.length}');

    if (currentUserId != null) {
      for (final habit in getAllHabits().take(5)) {
        final progressCount = getHabitProgress(habit.id).length;
        print('  • ${habit.name} (${habit.id}) - $progressCount progress entries');
      }
    }
    print('=== END DEBUG INFO ===');
  }

  static void debugAuthState() {
    print('=== DETAILED AUTH DEBUG ===');
    print('Hive Initialized: $isInitialized');

    // Check if boxes are open
    print('Boxes Open:');
    print('  Habits: ${Hive.isBoxOpen(_habitsBox)}');
    print('  Progress: ${Hive.isBoxOpen(_progressBox)}');
    print('  Settings: ${Hive.isBoxOpen(_settingsBox)}');
    print('  Users: ${Hive.isBoxOpen(_usersBox)}');

    // Check settings box contents
    print('Settings Box Contents:');
    final settingsBox = _settingsBoxInstance;
    for (final key in settingsBox.keys) {
      print('  $key: ${settingsBox.get(key)}');
    }

    print('Current User ID: "${getCurrentUserId()}"');
    print('Auth Token exists: ${getSetting('auth_token') != null}');
    print('User Data exists: ${getSetting('user_data') != null}');
    print('All Users: ${getAllUsers().map((u) => '${u.username} (${u.id})').join(', ')}');
    print('========================');
  }



  // ✅ Emergency method - use only for testing
  static Future<void> clearAllData() async {
    print('🚨 CLEARING ALL DATA - This will remove everything!');
    await _habitsBoxInstance.clear();
    await _progressBoxInstance.clear();
    await _settingsBoxInstance.clear();
    await _usersBoxInstance.clear();
  }
}
