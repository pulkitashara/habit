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

  // Remove habit immediately from UI state list (no DB operation)
  void removeHabitFromState(String habitId) {
    final updatedList = [...state.habits]..removeWhere((habit) => habit.id == habitId);
    state = state.copyWith(habits: updatedList);
  }

// Add habit immediately to UI state list (no DB operation)
  Future<void> addHabit(Habit habit) async {
    final updatedList = [habit, ...state.habits];
    state = state.copyWith(habits: updatedList);
    await HiveService.saveHabit(HabitModel.fromEntity(habit));
  }


  Future<void> _initializeData() async {
    //await HiveService.initializeSampleData();
    await loadHabits();
  }

  // In HabitProvider
  Future<void> loadHabits() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final currentUserId = HiveService.getCurrentUserId();
      print('🔍 Loading habits for user: $currentUserId'); // Debug log

      if (currentUserId == null) {
        print('❌ No current user ID found');
        state = state.copyWith(habits: [], isLoading: false);
        return;
      }

      // Load from local storage first
      final localHabits = HiveService.getAllHabits()
          .map((model) => model.toEntity())
          .toList();

      print('📊 Found ${localHabits.length} habits for user $currentUserId'); // Debug log

      localHabits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(habits: localHabits, isLoading: false);

      // Background API sync
      final authState = _ref.read(authProvider);
      if (authState.isAuthenticated && authState.token != null) {
        _syncWithApiInBackground(authState.token!);
      }
    } catch (e) {
      print('❌ Error loading habits: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load habits: ${e.toString()}',
      );
    }
  }


  void clearUserData() {
    // Clear habit state when user logs out
    state = HabitState();
    print('🧹 Cleared habit provider state');
  }



// ✅ Background sync that doesn't overwrite local progress
  Future<void> _syncWithApiInBackground(String token) async {
    try {
      state = state.copyWith(isSyncing: true);
      final response = await _apiService.getHabits(token);

      // ✅ Simple approach: Just update isSyncing status, keep local data
      state = state.copyWith(isSyncing: false, isOnline: true);

      // Optional: You can update with API data if needed, but preserve local progress
      if (response != null && response.isNotEmpty) {
        print('✅ API sync successful');
      }
    } catch (e) {
      print('Background sync failed: $e');
      state = state.copyWith(isSyncing: false, isOnline: false);
    }
  }




  Future<void> _syncWithApi(String token) async {
    try {
      state = state.copyWith(isSyncing: true);

      final response = await _apiService.getHabits(token);

      // ✅ FIX: Handle null response properly
      final apiHabits = (response ?? []).map((habitData) {
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
        error: null, // Don't show error for sync failures
      );
    }
  }


  Future<void> createHabit(Habit habit) async {
    final currentUserId = HiveService.getCurrentUserId();
    if (currentUserId == null) {
      state = state.copyWith(error: 'User not logged in');
      return;
    }

    try {
      // ✅ Add userId to habit
      final habitWithUser = habit.copyWith(userId: currentUserId);

      final habitModel = HabitModel.fromEntity(habitWithUser);
      await HiveService.saveHabit(habitModel);

      final updatedHabits = [habitWithUser, ...state.habits];
      state = state.copyWith(habits: updatedHabits);

      // Background API sync
      final authState = _ref.read(authProvider);
      if (authState.isAuthenticated && authState.token != null) {
        try {
          final habitData = habitWithUser.toJson();
          await _apiService.createHabit(authState.token!, habitData);
        } catch (e) {
          print('Failed to sync new habit to API: $e');
        }
      }
    } catch (e) {
      await loadHabits();
      state = state.copyWith(error: 'Failed to create habit: ${e.toString()}');
    }
  }

  Future<void> markHabitComplete(String habitId) async {
    final currentUserId = HiveService.getCurrentUserId();
    if (currentUserId == null) {
      state = state.copyWith(error: 'User not logged in');
      return;
    }

    try {
      final habitIndex = state.habits.indexWhere((h) => h.id == habitId);
      if (habitIndex == -1) return;

      final habit = state.habits[habitIndex];
      final now = DateTime.now();

      final todayProgress = HiveService.getTodayProgress(habitId);
      if (todayProgress?.isCompleted == true) {
        state = state.copyWith(error: 'Habit already completed today');
        return;
      }

      // ✅ Create progress with userId
      final progress = HabitProgress(
        id: '${habitId}_${now.millisecondsSinceEpoch}',
        habitId: habitId,
        date: now,
        completed: habit.targetCount,
        target: habit.targetCount,
        isCompleted: true,
        createdAt: now,
        userId: currentUserId, // ✅ Add user ID
      );

      final progressModel = HabitProgressModel.fromEntity(progress);
      await HiveService.saveProgress(progressModel);

      // Recalculate stats
      final newStreak = HiveService.calculateCurrentStreak(habitId);
      final newCompletionRate = HiveService.calculateCompletionRate(habitId);

      final updatedHabit = habit.copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
        completionRate: newCompletionRate,
      );

      await HiveService.saveHabit(HabitModel.fromEntity(updatedHabit));

      final updatedHabits = List<Habit>.from(state.habits);
      updatedHabits[habitIndex] = updatedHabit;

      final updatedProgress = Map<String, List<HabitProgress>>.from(state.habitProgress);
      updatedProgress[habitId] = [progress, ...(updatedProgress[habitId] ?? [])];

      state = state.copyWith(
        habits: updatedHabits,
        habitProgress: updatedProgress,
      );

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
