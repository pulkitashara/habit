import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_progress.dart';
import '../../core/utils/date_utils.dart';

class HabitState {
  final bool isLoading;
  final bool isLoadingProgress;
  final List<Habit> habits;
  final Map<String, List<HabitProgress>> habitProgress;
  final String? error;

  HabitState({
    this.isLoading = false,
    this.isLoadingProgress = false,
    this.habits = const [],
    this.habitProgress = const {},
    this.error,
  });

  HabitState copyWith({
    bool? isLoading,
    bool? isLoadingProgress,
    List<Habit>? habits,
    Map<String, List<HabitProgress>>? habitProgress,
    String? error,
  }) {
    return HabitState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingProgress: isLoadingProgress ?? this.isLoadingProgress,
      habits: habits ?? this.habits,
      habitProgress: habitProgress ?? this.habitProgress,
      error: error,
    );
  }
}

class HabitNotifier extends StateNotifier<HabitState> {
  HabitNotifier() : super(HabitState());

  Future<void> loadHabits() async {
    state = state.copyWith(isLoading: true, error: null);

    await Future.delayed(const Duration(seconds: 1));

    // Mock habits with more realistic data
    final mockHabits = [
      Habit(
        id: '1',
        name: 'Morning Exercise',
        description: '30 minutes of exercise every morning to start the day right',
        category: 'fitness',
        targetCount: 1,
        frequency: 'daily',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        updatedAt: DateTime.now(),
        isActive: true,
        color: '#FF6B6B',
        icon: 'fitness_center',
        currentStreak: 5,
        longestStreak: 12,
        completionRate: 0.75,
      ),
      Habit(
        id: '2',
        name: 'Drink Water',
        description: 'Drink 8 glasses of water throughout the day for proper hydration',
        category: 'nutrition',
        targetCount: 8,
        frequency: 'daily',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
        isActive: true,
        color: '#4ECDC4',
        icon: 'local_drink',
        currentStreak: 3,
        longestStreak: 8,
        completionRate: 0.60,
      ),
      Habit(
        id: '3',
        name: 'Meditation',
        description: '10 minutes of mindfulness meditation for mental clarity',
        category: 'mindfulness',
        targetCount: 1,
        frequency: 'daily',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now(),
        isActive: true,
        color: '#45B7D1',
        icon: 'self_improvement',
        currentStreak: 7,
        longestStreak: 7,
        completionRate: 0.95,
      ),
      Habit(
        id: '4',
        name: 'Read Books',
        description: 'Read for 30 minutes daily to expand knowledge',
        category: 'productivity',
        targetCount: 1,
        frequency: 'daily',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
        isActive: true,
        color: '#96CEB4',
        icon: 'menu_book',
        currentStreak: 2,
        longestStreak: 4,
        completionRate: 0.40,
      ),
    ];

    state = state.copyWith(isLoading: false, habits: mockHabits, error: null);
  }

  Future<void> markHabitComplete(String habitId) async {
    final today = DateTime.now();

    // Create progress entry for today
    final progress = HabitProgress(
      id: '${habitId}_${today.millisecondsSinceEpoch}',
      habitId: habitId,
      date: today,
      completed: 1,
      target: 1,
      isCompleted: true,
      createdAt: today,
    );

    // Update habit progress map
    final updatedProgress = Map<String, List<HabitProgress>>.from(state.habitProgress);
    final habitProgressList = updatedProgress[habitId] ?? [];

    // Remove existing entry for today if any
    habitProgressList.removeWhere((p) => DateUtilsHelper.isSameDay(p.date, today));

    // Add new entry
    habitProgressList.add(progress);
    updatedProgress[habitId] = habitProgressList;

    // Update habit streak and completion rate
    final updatedHabits = state.habits.map((habit) {
      if (habit.id == habitId) {
        final newStreak = habit.currentStreak + 1;
        return Habit(
          id: habit.id,
          name: habit.name,
          description: habit.description,
          category: habit.category,
          targetCount: habit.targetCount,
          frequency: habit.frequency,
          createdAt: habit.createdAt,
          updatedAt: DateTime.now(),
          isActive: habit.isActive,
          color: habit.color,
          icon: habit.icon,
          currentStreak: newStreak,
          longestStreak: newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
          completionRate: _calculateCompletionRate(habitProgressList),
        );
      }
      return habit;
    }).toList();

    state = state.copyWith(
      habits: updatedHabits,
      habitProgress: updatedProgress,
    );
  }

  Future<void> loadHabitProgress(String habitId) async {
    state = state.copyWith(isLoadingProgress: true);

    await Future.delayed(const Duration(milliseconds: 500));

    // Generate mock progress data for the last 30 days
    final mockProgress = _generateMockProgress(habitId);

    final updatedProgress = Map<String, List<HabitProgress>>.from(state.habitProgress);
    updatedProgress[habitId] = mockProgress;

    state = state.copyWith(
      isLoadingProgress: false,
      habitProgress: updatedProgress,
    );
  }

  Future<void> deleteHabit(String habitId) async {
    final updatedHabits = state.habits.where((h) => h.id != habitId).toList();
    final updatedProgress = Map<String, List<HabitProgress>>.from(state.habitProgress);
    updatedProgress.remove(habitId);

    state = state.copyWith(
      habits: updatedHabits,
      habitProgress: updatedProgress,
    );
  }

  List<HabitProgress> _generateMockProgress(String habitId) {
    final progress = <HabitProgress>[];
    final now = DateTime.now();

    // Generate random progress for last 30 days
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));

      // 70% chance of completion for variety
      final isCompleted = (i * 7 + int.parse(habitId)) % 10 < 7;

      if (isCompleted || i < 7) { // Always show last 7 days
        progress.add(
          HabitProgress(
            id: '${habitId}_${date.millisecondsSinceEpoch}',
            habitId: habitId,
            date: date,
            completed: isCompleted ? 1 : 0,
            target: 1,
            isCompleted: isCompleted,
            createdAt: date,
            notes: isCompleted ? null : 'Missed this day',
          ),
        );
      }
    }

    return progress.reversed.toList(); // Chronological order
  }

  double _calculateCompletionRate(List<HabitProgress> progressList) {
    if (progressList.isEmpty) return 0.0;

    final completedDays = progressList.where((p) => p.isCompleted).length;
    return completedDays / progressList.length;
  }
}

final habitProvider = StateNotifierProvider<HabitNotifier, HabitState>((ref) {
  return HabitNotifier();
});
