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

  // Boxes
  static Box<HabitModel> get _habitsHive => Hive.box<HabitModel>(_habitsBox);
  static Box<HabitProgressModel> get _progressHive => Hive.box<HabitProgressModel>(_progressBox);
  static Box get _settingsHive => Hive.box(_settingsBox);

  // HABITS CRUD
  static Future<void> saveHabit(HabitModel habit) async {
    await _habitsHive.put(habit.id, habit);
  }

  static List<HabitModel> getAllHabits() {
    return _habitsHive.values.where((habit) => habit.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static HabitModel? getHabit(String id) {
    return _habitsHive.get(id);
  }

  static Future<void> updateHabit(HabitModel habit) async {
    await _habitsHive.put(habit.id, habit);
  }

  static Future<void> deleteHabit(String id) async {
    await _habitsHive.delete(id);
    // Also delete related progress
    final progressToDelete = _progressHive.values
        .where((progress) => progress.habitId == id)
        .toList();

    for (final progress in progressToDelete) {
      await progress.delete();
    }
  }

  // PROGRESS CRUD
  static Future<void> saveProgress(HabitProgressModel progress) async {
    await _progressHive.put(progress.id, progress);
  }

  static List<HabitProgressModel> getHabitProgress(String habitId) {
    return _progressHive.values
        .where((p) => p.habitId == habitId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static HabitProgressModel? getTodayProgress(String habitId) {
    final today = DateUtilsHelper.startOfDay(DateTime.now());
    try {
      return _progressHive.values.firstWhere(
            (progress) =>
        progress.habitId == habitId &&
            DateUtilsHelper.isSameDay(progress.date, today),
      );
    } catch (e) {
      return null; // ✅ Fixed nullable access
    }
  }

  static bool isHabitCompletedToday(String habitId) {
    final todayProgress = getTodayProgress(habitId);
    return todayProgress?.isCompleted ?? false; // ✅ Fixed nullable access
  }

  static Future<void> markHabitComplete(String habitId, int targetCount) async {
    final today = DateTime.now();
    final progressId = '${habitId}_${today.millisecondsSinceEpoch}';

    // Check if already completed today
    if (isHabitCompletedToday(habitId)) return;

    final progress = HabitProgressModel(
      id: progressId,
      habitId: habitId,
      date: today,
      completed: targetCount,
      target: targetCount,
      isCompleted: true,
      createdAt: today,
    );

    await saveProgress(progress);

    // Update habit streak and completion rate
    await _updateHabitStats(habitId);
  }

  static Future<void> _updateHabitStats(String habitId) async {
    final habit = getHabit(habitId);
    if (habit == null) return;

    final allProgress = getHabitProgress(habitId);

    // Calculate streak
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    final sortedProgress = allProgress
      ..sort((a, b) => a.date.compareTo(b.date));

    DateTime? lastDate;
    for (final progress in sortedProgress) {
      if (progress.isCompleted) {
        if (lastDate == null ||
            DateUtilsHelper.getDaysDifference(progress.date, lastDate) == 1) {
          tempStreak++;
        } else {
          tempStreak = 1;
        }

        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }

        // Check if this continues to today
        if (DateUtilsHelper.isToday(progress.date) ||
            DateUtilsHelper.getDaysDifference(DateTime.now(), progress.date) <= tempStreak) {
          currentStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
      lastDate = progress.date;
    }

    // Calculate completion rate
    final totalDays = DateTime.now().difference(habit.createdAt).inDays + 1;
    final completedDays = allProgress.where((p) => p.isCompleted).length;
    final completionRate = totalDays > 0 ? completedDays / totalDays : 0.0;

    // Update habit
    final updatedHabit = habit.copyWith(
      currentStreak: currentStreak,
      longestStreak: longestStreak > habit.longestStreak ? longestStreak : habit.longestStreak,
      completionRate: completionRate,
      updatedAt: DateTime.now(),
    );

    await saveHabit(updatedHabit);
  }

  // SETTINGS
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsHive.put(key, value);
  }

  static T? getSetting<T>(String key) {
    return _settingsHive.get(key) as T?;
  }

  // Initialize with sample data if empty
  static Future<void> initializeSampleData() async {
    if (_habitsHive.isEmpty) {
      final sampleHabits = [
        HabitModel(
          id: '1',
          name: 'Morning Exercise',
          description: '30 minutes of exercise every morning',
          category: 'fitness',
          targetCount: 1,
          frequency: 'daily',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now(),
          isActive: true,
          color: '#FF6B6B',
          icon: 'fitness_center',
          currentStreak: 0,
          longestStreak: 0,
          completionRate: 0.0,
        ),
        HabitModel(
          id: '2',
          name: 'Drink Water',
          description: 'Drink 8 glasses of water daily',
          category: 'nutrition',
          targetCount: 8,
          frequency: 'daily',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now(),
          isActive: true,
          color: '#4ECDC4',
          icon: 'local_drink',
          currentStreak: 0,
          longestStreak: 0,
          completionRate: 0.0,
        ),
        HabitModel(
          id: '3',
          name: 'Read Books',
          description: 'Read for 30 minutes daily',
          category: 'productivity',
          targetCount: 1,
          frequency: 'daily',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now(),
          isActive: true,
          color: '#96CEB4',
          icon: 'menu_book',
          currentStreak: 0,
          longestStreak: 0,
          completionRate: 0.0,
        ),
      ];

      for (final habit in sampleHabits) {
        await saveHabit(habit);
      }
    }
  }

  // ✅ Fixed ValueListenable methods
  static ValueListenable<Box<HabitModel>> watchHabits() {
    return _habitsHive.listenable();
  }

  static ValueListenable<Box<HabitProgressModel>> watchProgress() {
    return _progressHive.listenable();
  }
}
