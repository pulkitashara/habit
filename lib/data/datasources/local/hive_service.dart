import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/habit_model.dart';
import '../../models/habit_progress_model.dart';
import '../../models/user_model.dart';

class HiveService {
  static const String _habitsBox = 'habits';
  static const String _progressBox = 'progress';
  static const String _settingsBox = 'settings';

  static bool _isInitialized = false;

  static Future<void> initializeHive() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    Hive.registerAdapter(HabitModelAdapter());
    Hive.registerAdapter(HabitProgressModelAdapter());
    Hive.registerAdapter(UserModelAdapter());

    await Hive.openBox<HabitModel>(_habitsBox);
    await Hive.openBox<HabitProgressModel>(_progressBox);
    await Hive.openBox(_settingsBox);

    _isInitialized = true;
  }

  static Box<HabitModel> get _habitsBoxInstance => Hive.box<HabitModel>(_habitsBox);
  static Box<HabitProgressModel> get _progressBoxInstance => Hive.box<HabitProgressModel>(_progressBox);
  static Box get _settingsBoxInstance => Hive.box(_settingsBox);

  // ✅ User management methods
  static Future<void> setCurrentUser(String userId) async {
    await _settingsBoxInstance.put('current_user_id', userId);
  }

  static String? getCurrentUserId() {
    return _settingsBoxInstance.get('current_user_id');
  }

  // ✅ Filter habits by current user
  static List<HabitModel> getAllHabits() {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return [];

    return _habitsBoxInstance.values
        .where((habit) => habit.userId == currentUserId)
        .toList();
  }

  static Future<void> saveHabit(HabitModel habit) async {
    await _habitsBoxInstance.put(habit.id, habit);
  }

  static HabitModel? getHabit(String habitId) {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return null;

    final habit = _habitsBoxInstance.get(habitId);
    return (habit?.userId == currentUserId) ? habit : null;
  }

  static Future<void> deleteHabit(String habitId) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return;

    await _habitsBoxInstance.delete(habitId);

    // Also delete all progress for this habit belonging to current user
    final progressBox = _progressBoxInstance;
    final keysToDelete = <String>[];

    for (final entry in progressBox.toMap().entries) {
      if (entry.value.habitId == habitId && entry.value.userId == currentUserId) {
        keysToDelete.add(entry.key);
      }
    }

    for (final key in keysToDelete) {
      await progressBox.delete(key);
    }
  }

  // ✅ Progress operations with user filtering
  static Future<void> saveProgress(HabitProgressModel progress) async {
    final dateKey = '${progress.habitId}_${_getDateKey(progress.date)}';
    await _progressBoxInstance.put(dateKey, progress);
  }

  static List<HabitProgressModel> getHabitProgress(String habitId) {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return [];

    return _progressBoxInstance.values
        .where((progress) => progress.habitId == habitId && progress.userId == currentUserId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static HabitProgressModel? getTodayProgress(String habitId) {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return null;

    final today = DateTime.now();
    final todayKey = '${habitId}_${_getDateKey(today)}';
    final progress = _progressBoxInstance.get(todayKey);
    return (progress?.userId == currentUserId) ? progress : null;
  }

  static HabitProgressModel? getProgressForDate(String habitId, DateTime date) {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return null;

    final dateKey = '${habitId}_${_getDateKey(date)}';
    final progress = _progressBoxInstance.get(dateKey);
    return (progress?.userId == currentUserId) ? progress : null;
  }

  // ✅ Calculate streak for current user only
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
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
    }

    return streak;
  }

  // ✅ Calculate completion rate properly
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

  // ✅ Clear data for specific user on logout
  static Future<void> clearDataForUser(String userId) async {
    // Clear habits for this user
    final habitsToDelete = _habitsBoxInstance.values
        .where((habit) => habit.userId == userId)
        .map((habit) => habit.key)
        .toList();

    await _habitsBoxInstance.deleteAll(habitsToDelete);

    // Clear progress for this user
    final progressToDelete = _progressBoxInstance.values
        .where((progress) => progress.userId == userId)
        .map((progress) => progress.key)
        .toList();

    await _progressBoxInstance.deleteAll(progressToDelete);
  }

  static Future<void> saveSetting<T>(String key, T value) async {
    await _settingsBoxInstance.put(key, value);
  }

  static T? getSetting<T>(String key) {
    return _settingsBoxInstance.get(key);
  }

  static String _getDateKey(DateTime date) {
    return '${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}';
  }

  static bool get isInitialized {
    try {
      return Hive.isBoxOpen('habits') && Hive.isBoxOpen('progress');
    } catch (e) {
      return false;
    }
  }

  static void debugPrintStorage() {
    final currentUserId = getCurrentUserId();
    print('=== HIVE DEBUG INFO ===');
    print('Current User ID: $currentUserId');
    print('Habits count (current user): ${getAllHabits().length}');
    print('Total habits count: ${_habitsBoxInstance.length}');
    print('Total progress count: ${_progressBoxInstance.length}');

    for (final habit in getAllHabits()) {
      print('Habit: ${habit.name} (ID: ${habit.id}, User: ${habit.userId})');
    }
    print('=== END DEBUG INFO ===');
  }

  static Future<void> clearAllData() async {
    await _habitsBoxInstance.clear();
    await _progressBoxInstance.clear();
    await _settingsBoxInstance.clear();
  }
}
