import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/habit_model.dart';
import '../../models/habit_progress_model.dart';
import '../../models/user_model.dart';
import '../../../core/utils/date_utils.dart';

class HiveService {
  static const String _habitsBox = 'habits';
  static const String _progressBox = 'progress';
  static const String _settingsBox = 'settings';

  // Add this flag to prevent re-initialization
  static bool _isInitialized = false;

  // ✅ Single initialization method
  static Future<void> initializeHive() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(HabitModelAdapter());
    Hive.registerAdapter(HabitProgressModelAdapter());
    Hive.registerAdapter(UserModelAdapter());

    // Open boxes and wait for them
    await Hive.openBox<HabitModel>(_habitsBox);
    await Hive.openBox<HabitProgressModel>(_progressBox);
    await Hive.openBox(_settingsBox);

    _isInitialized = true;

    // ✅ Only run sample data initialization once per app install
    // await _initializeSampleDataIfNeeded();
  }

  // ✅ Prevent default habits from showing up
  // static Future<void> _initializeSampleDataIfNeeded() async {
  //   final settings = Hive.box(_settingsBox);
  //   final hasInitialized = settings.get('sample_data_initialized', defaultValue: false);
  //
  //   if (!hasInitialized) {
  //     // Mark as initialized but don't add any sample data
  //     await settings.put('sample_data_initialized', true);
  //     // User will create their own habits
  //   }
  // }

  // Getter methods for boxes
  static Box<HabitModel> get _habitsBoxInstance => Hive.box<HabitModel>(_habitsBox);
  static Box<HabitProgressModel> get _progressBoxInstance => Hive.box<HabitProgressModel>(_progressBox);
  static Box get _settingsBoxInstance => Hive.box(_settingsBox);

  // ✅ Habit CRUD operations
  static Future<void> saveHabit(HabitModel habit) async {
    await _habitsBoxInstance.put(habit.id, habit);
  }

  static List<HabitModel> getAllHabits() {
    return _habitsBoxInstance.values.toList();
  }

  static HabitModel? getHabit(String habitId) {
    return _habitsBoxInstance.get(habitId);
  }

  static Future<void> deleteHabit(String habitId) async {
    await _habitsBoxInstance.delete(habitId);

    // Also delete all progress for this habit
    final progressBox = _progressBoxInstance;
    final keysToDelete = <String>[];

    for (final entry in progressBox.toMap().entries) {
      if (entry.value.habitId == habitId) {
        keysToDelete.add(entry.key);
      }
    }

    for (final key in keysToDelete) {
      await progressBox.delete(key);
    }
  }

  // ✅ Progress operations with date-based keys
  static Future<void> saveProgress(HabitProgressModel progress) async {
    // ✅ Use date-based key for consistent daily tracking
    final dateKey = '${progress.habitId}_${_getDateKey(progress.date)}';
    await _progressBoxInstance.put(dateKey, progress);
  }

  static List<HabitProgressModel> getHabitProgress(String habitId) {
    return _progressBoxInstance.values
        .where((progress) => progress.habitId == habitId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort newest first
  }

  // ✅ Get today's progress using date-only comparison
  static HabitProgressModel? getTodayProgress(String habitId) {
    final today = DateTime.now();
    final todayKey = '${habitId}_${_getDateKey(today)}';
    return _progressBoxInstance.get(todayKey);
  }

  // ✅ Check if habit is completed on specific date
  static HabitProgressModel? getProgressForDate(String habitId, DateTime date) {
    final dateKey = '${habitId}_${_getDateKey(date)}';
    return _progressBoxInstance.get(dateKey);
  }

  // ✅ Calculate streak properly across dates
  static int calculateCurrentStreak(String habitId) {
    final allProgress = getHabitProgress(habitId)
        .where((p) => p.isCompleted)
        .toList();

    if (allProgress.isEmpty) return 0;

    allProgress.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime checkDate = DateTime.now();

    // Check consecutive days backwards from today
    for (int i = 0; i < 365; i++) { // Max check to prevent infinite loop
      final progress = getProgressForDate(habitId, checkDate);

      if (progress?.isCompleted == true) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (i == 0) {
        // If today isn't completed, check yesterday
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
    }

    return streak;
  }

  // ✅ Calculate completion rate
  static double calculateCompletionRate(String habitId) {
    final habit = _habitsBoxInstance.get(habitId);
    if (habit == null) return 0.0;

    final daysSinceCreation = DateTime.now().difference(habit.createdAt).inDays + 1;
    final completedDays = getHabitProgress(habitId)
        .where((p) => p.isCompleted)
        .length;
    return daysSinceCreation > 0 ? completedDays / daysSinceCreation : 0.0;
  }

  // ✅ Settings operations
  static Future<void> saveSetting<T>(String key, T value) async {
    await _settingsBoxInstance.put(key, value);
  }

  static T? getSetting<T>(String key) {
    return _settingsBoxInstance.get(key);
  }

  // ✅ Helper methods for date handling
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

  static bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ✅ Debug method to check what's in storage
  static void debugPrintStorage() {
    print('=== HIVE DEBUG INFO ===');
    print('Habits count: ${_habitsBoxInstance.length}');
    print('Progress count: ${_progressBoxInstance.length}');
    print('Settings: ${_settingsBoxInstance.toMap()}');

    for (final habit in _habitsBoxInstance.values) {
      print('Habit: ${habit.name} (ID: ${habit.id})');
    }

    for (final entry in _progressBoxInstance.toMap().entries) {
      final progress = entry.value;
      print('Progress: ${entry.key} -> ${progress.habitId} on ${progress.date} (completed: ${progress.isCompleted})');
    }
    print('=== END DEBUG INFO ===');
  }

  // ✅ Method to clear all data (useful for testing)
  static Future<void> clearAllData() async {
    await _habitsBoxInstance.clear();
    await _progressBoxInstance.clear();
    await _settingsBoxInstance.clear();
  }
}


