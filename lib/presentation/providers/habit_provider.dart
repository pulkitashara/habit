import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_progress.dart';
import '../../data/datasources/local/hive_service.dart';
import '../../data/models/habit_model.dart';

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
  HabitNotifier() : super(HabitState()) {
    _initializeData();
    _setupListeners();
  }

  Future<void> _initializeData() async {
    // Initialize sample data if empty
    await HiveService.initializeSampleData();
    await loadHabits();
  }

  void _setupListeners() {
    // Listen to Hive changes for reactive UI
    HiveService.watchHabits().addListener(_onHabitsChanged);
    HiveService.watchProgress().addListener(_onProgressChanged);
  }

  void _onHabitsChanged() {
    loadHabits();
  }

  void _onProgressChanged() {
    // Reload progress for all habits
    for (final habit in state.habits) {
      loadHabitProgress(habit.id);
    }
  }

  Future<void> loadHabits() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final habitModels = HiveService.getAllHabits();
      final habits = habitModels.map((model) => model.toEntity()).toList();

      state = state.copyWith(
        isLoading: false,
        habits: habits,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load habits: ${e.toString()}',
      );
    }
  }

  Future<void> createHabit(Habit habit) async {
    try {
      final habitModel = HabitModel.fromEntity(habit);
      await HiveService.saveHabit(habitModel);

      // Habits will be automatically reloaded via listener
    } catch (e) {
      state = state.copyWith(error: 'Failed to create habit: ${e.toString()}');
    }
  }

  Future<void> markHabitComplete(String habitId) async {
    try {
      final habit = state.habits.firstWhere((h) => h.id == habitId);
      await HiveService.markHabitComplete(habitId, habit.targetCount);

      // Progress and habits will be automatically reloaded via listeners
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark habit complete: ${e.toString()}');
    }
  }

  Future<void> loadHabitProgress(String habitId) async {
    state = state.copyWith(isLoadingProgress: true);

    try {
      final progressModels = HiveService.getHabitProgress(habitId);
      final progress = progressModels.map((model) => model.toEntity()).toList();

      final updatedProgress = Map<String, List<HabitProgress>>.from(state.habitProgress);
      updatedProgress[habitId] = progress;

      state = state.copyWith(
        isLoadingProgress: false,
        habitProgress: updatedProgress,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingProgress: false,
        error: 'Failed to load progress: ${e.toString()}',
      );
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await HiveService.deleteHabit(habitId);

      // Remove from progress map
      final updatedProgress = Map<String, List<HabitProgress>>.from(state.habitProgress);
      updatedProgress.remove(habitId);

      state = state.copyWith(habitProgress: updatedProgress);

      // Habits will be automatically reloaded via listener
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete habit: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    // Clean up listeners
    HiveService.watchHabits().removeListener(_onHabitsChanged);
    HiveService.watchProgress().removeListener(_onProgressChanged);
    super.dispose();
  }
}

final habitProvider = StateNotifierProvider<HabitNotifier, HabitState>((ref) {
  return HabitNotifier();
});

// Provider to check if a habit is completed today
final habitCompletionProvider = Provider.family<bool, String>((ref, habitId) {
  return HiveService.isHabitCompletedToday(habitId);
});
