import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_progress.dart';
import '../../data/datasources/local/hive_service.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/habit_progress_model.dart';
import '../../data/services/api_service.dart';
import 'auth_provider.dart';
import 'api_providers.dart';

class HabitState {
  final bool isLoading;
  final bool isLoadingProgress;
  final bool isSyncing;
  final List<Habit> habits;
  final Map<String, List<HabitProgress>> habitProgress;
  final String? error;
  final bool isOnline;

  HabitState({
    this.isLoading = false,
    this.isLoadingProgress = false,
    this.isSyncing = false,
    this.habits = const [],
    this.habitProgress = const {},
    this.error,
    this.isOnline = true,
  });

  HabitState copyWith({
    bool? isLoading,
    bool? isLoadingProgress,
    bool? isSyncing,
    List<Habit>? habits,
    Map<String, List<HabitProgress>>? habitProgress,
    String? error,
    bool? isOnline,
  }) {
    return HabitState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingProgress: isLoadingProgress ?? this.isLoadingProgress,
      isSyncing: isSyncing ?? this.isSyncing,
      habits: habits ?? this.habits,
      habitProgress: habitProgress ?? this.habitProgress,
      error: error,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class HabitNotifier extends StateNotifier<HabitState> {
  final ApiService _apiService;
  final Ref _ref;

  HabitNotifier(this._apiService, this._ref) : super(HabitState()) {
    _initializeData();
  }

  Future<void> _initializeData() async {
    //await HiveService.initializeSampleData();
    await loadHabits();
  }

  Future<void> loadHabits() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load from local storage first
      final localHabits = HiveService.getAllHabits()
          .map((model) => model.toEntity())
          .toList();

      // Sort by creation date for consistency (newest first)
      localHabits.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(habits: localHabits, isLoading: false);

      // Try to sync with API if authenticated
      final authState = _ref.read(authProvider);
      if (authState.isAuthenticated && authState.token != null) {
        await _syncWithApi(authState.token!);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load habits: ${e.toString()}',
      );
    }
  }

  Future<void> _syncWithApi(String token) async {
    try {
      state = state.copyWith(isSyncing: true);

      final response = await _apiService.getHabits(token);

      // Convert API response to habits
      final apiHabits = response.map((habitData) {
        return Habit.fromJson(habitData);
      }).toList();

      // Sort for consistency
      apiHabits.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(
        habits: apiHabits,
        isSyncing: false,
        isOnline: true,
      );

      // Update local storage with API data
      await _updateLocalHabits(apiHabits);

    } catch (e) {
      print('Failed to sync habits from API: $e');
      state = state.copyWith(
        isSyncing: false,
        isOnline: false,
        error: 'Using offline data. Sync failed.',
      );
    }
  }

  Future<void> createHabit(Habit habit) async {
    try {
      // Save locally first
      final habitModel = HabitModel.fromEntity(habit);
      await HiveService.saveHabit(habitModel);

      // Optimistic update - add to UI immediately
      final updatedHabits = [habit, ...state.habits];
      state = state.copyWith(habits: updatedHabits);

      // Try to sync with API
      final authState = _ref.read(authProvider);
      if (authState.isAuthenticated && authState.token != null) {
        try {
          final habitData = habit.toJson();
          final response = await _apiService.createHabit(authState.token!, habitData);

          // Update local habit with server ID if different
          if (response['id'] != habit.id) {
            await HiveService.deleteHabit(habit.id);
            final serverHabit = habit.copyWith(
              id: response['id'],
              updatedAt: DateTime.parse(response['updatedAt']),
            );
            final serverHabitModel = HabitModel.fromEntity(serverHabit);
            await HiveService.saveHabit(serverHabitModel);

            // Update state with server habit
            final index = updatedHabits.indexWhere((h) => h.id == habit.id);
            if (index != -1) {
              updatedHabits[index] = serverHabit;
              state = state.copyWith(habits: List.from(updatedHabits));
            }
          }
        } catch (e) {
          print('Failed to sync new habit to API: $e');
          // Habit is still saved locally and shown in UI
        }
      }
    } catch (e) {
      // Rollback optimistic update on error
      await loadHabits();
      state = state.copyWith(error: 'Failed to create habit: ${e.toString()}');
    }
  }

  Future<void> markHabitComplete(String habitId) async {
    try {
      final habitIndex = state.habits.indexWhere((h) => h.id == habitId);
      if (habitIndex == -1) return;

      final habit = state.habits[habitIndex];
      final now = DateTime.now();

      // ✅ Check if already completed today using date-only comparison
      final todayProgress = HiveService.getTodayProgress(habitId);
      if (todayProgress?.isCompleted == true) {
        state = state.copyWith(error: 'Habit already completed today');
        return;
      }

      final progress = HabitProgress(
        id: '${habitId}_${now.millisecondsSinceEpoch}',
        habitId: habitId,
        date: now,
        completed: habit.targetCount,
        target: habit.targetCount,
        isCompleted: true,
        createdAt: now,
      );

      // ✅ Save progress with date-based key
      final progressModel = HabitProgressModel.fromEntity(progress);
      await HiveService.saveProgress(progressModel);

      // ✅ Recalculate stats properly
      final newStreak = HiveService.calculateCurrentStreak(habitId);
      final newCompletionRate = HiveService.calculateCompletionRate(habitId);

      // Update habit with new stats
      final updatedHabits = List<Habit>.from(state.habits);
      updatedHabits[habitIndex] = habit.copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
        completionRate: newCompletionRate,
      );

      // ✅ Update local Hive storage
      final updatedHabitModel = HabitModel.fromEntity(updatedHabits[habitIndex]);
      await HiveService.saveHabit(updatedHabitModel);

      // Update progress map for UI
      final updatedProgress = Map<String, List<HabitProgress>>.from(state.habitProgress);
      if (!updatedProgress.containsKey(habitId)) {
        updatedProgress[habitId] = [];
      }
      updatedProgress[habitId] = [progress, ...updatedProgress[habitId]!];

      state = state.copyWith(
        habits: updatedHabits,
        habitProgress: updatedProgress,
      );

      // Try API sync in background
      final authState = _ref.read(authProvider);
      if (authState.isAuthenticated && authState.token != null) {
        try {
          final progressData = progress.toJson();
          await _apiService.updateHabitProgress(authState.token!, habitId, progressData);
        } catch (e) {
          print('Failed to sync progress to API: $e');
        }
      }

    } catch (e) {
      state = state.copyWith(error: 'Failed to mark habit complete: ${e.toString()}');
    }
  }


  Future<void> loadHabitProgress(String habitId) async {
    state = state.copyWith(isLoadingProgress: true);

    try {
      final progressModels = HiveService.getHabitProgress(habitId);
      final progress = progressModels.map((model) => model.toEntity()).toList();

      // Sort by date descending
      progress.sort((a, b) => b.date.compareTo(a.date));

      final updatedProgress = Map<String, List<HabitProgress>>.from(state.habitProgress);
      updatedProgress[habitId] = progress;

      state = state.copyWith(
        isLoadingProgress: false,
        habitProgress: updatedProgress,
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
      // Delete locally first
      await HiveService.deleteHabit(habitId);

      // Optimistic update
      final updatedHabits = state.habits.where((h) => h.id != habitId).toList();
      final updatedProgress = Map<String, List<HabitProgress>>.from(state.habitProgress);
      updatedProgress.remove(habitId);

      state = state.copyWith(
        habits: updatedHabits,
        habitProgress: updatedProgress,
      );

      // Try to sync with API
      final authState = _ref.read(authProvider);
      if (authState.isAuthenticated && authState.token != null) {
        try {
          await _apiService.deleteHabit(authState.token!, habitId);
        } catch (e) {
          print('Failed to delete habit on server: $e');
        }
      }
    } catch (e) {
      // Rollback on error
      await loadHabits();
      state = state.copyWith(error: 'Failed to delete habit: ${e.toString()}');
    }
  }

  Future<void> _updateLocalHabits(List<Habit> apiHabits) async {
    try {
      // Clear local habits
      final localHabits = HiveService.getAllHabits();
      for (final habit in localHabits) {
        await HiveService.deleteHabit(habit.id);
      }

      // Save API habits locally
      for (final habit in apiHabits) {
        final model = HabitModel.fromEntity(habit);
        await HiveService.saveHabit(model);
      }
    } catch (e) {
      print('Failed to update local habits: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final habitProvider = StateNotifierProvider<HabitNotifier, HabitState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return HabitNotifier(apiService, ref);
});
