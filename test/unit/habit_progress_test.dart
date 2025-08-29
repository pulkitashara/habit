import 'package:flutter_test/flutter_test.dart';
import 'package:habit_builder/domain/entities/habit.dart';
import 'package:habit_builder/domain/entities/habit_progress.dart';

void main() {
  group('Habit Progress Calculation Tests', () {
    test('should calculate current streak correctly - consecutive days', () {
      // Arrange: 3 consecutive completed days from most recent
      final progressList = [
        HabitProgress(
          id: 'p1',
          habitId: 'habit_test_123',
          date: DateTime.now(),
          completed: 1,
          target: 1,
          isCompleted: true,
          createdAt: DateTime.now(),
          userId: 'user123',
        ),
        HabitProgress(
          id: 'p2',
          habitId: 'habit_test_123',
          date: DateTime.now().subtract(const Duration(days: 1)),
          completed: 1,
          target: 1,
          isCompleted: true,
          createdAt: DateTime.now(),
          userId: 'user123',
        ),
        HabitProgress(
          id: 'p3',
          habitId: 'habit_test_123',
          date: DateTime.now().subtract(const Duration(days: 2)),
          completed: 1,
          target: 1,
          isCompleted: true,
          createdAt: DateTime.now(),
          userId: 'user123',
        ),
        HabitProgress(
          id: 'p4',
          habitId: 'habit_test_123',
          date: DateTime.now().subtract(const Duration(days: 3)),
          completed: 0,
          target: 1,
          isCompleted: false,
          createdAt: DateTime.now(),
          userId: 'user123',
        ),
      ];

      // Act
      final currentStreak = _calculateCurrentStreak(progressList);

      // Assert
      expect(currentStreak, 3);
    });

    test('should calculate completion rate correctly', () {
      // Arrange: 7 out of 10 days completed
      final progressList = List.generate(10, (index) {
        final isCompleted = index < 7;
        return HabitProgress(
          id: 'p$index',
          habitId: 'habit_test_123',
          date: DateTime.now().subtract(Duration(days: 9 - index)),
          completed: isCompleted ? 1 : 0,
          target: 1,
          isCompleted: isCompleted,
          createdAt: DateTime.now(),
          userId: 'user123',
        );
      });

      // Act
      final completionRate = _calculateCompletionRate(progressList);

      // Assert
      expect(completionRate, 0.7);
    });

    test('should handle empty progress list', () {
      // Arrange
      final progressList = <HabitProgress>[];

      // Act & Assert
      expect(_calculateCurrentStreak(progressList), 0);
      expect(_calculateCompletionRate(progressList), 0.0);
    });
  });

  group('Habit Model Tests', () {
    test('should create habit with correct properties', () {
      // Arrange & Act
      final habit = Habit(
        id: 'test123',
        name: 'Test Habit',
        description: 'Test Description',
        category: 'fitness',
        targetCount: 2,
        frequency: 'daily',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
        isActive: true,
        color: '#4ECDC4',
        icon: 'fitness_center',
        currentStreak: 5,
        longestStreak: 10,
        completionRate: 0.8,
        userId: 'user456',
      );

      // Assert
      expect(habit.name, 'Test Habit');
      expect(habit.category, 'fitness');
      expect(habit.targetCount, 2);
      expect(habit.currentStreak, 5);
      expect(habit.completionRate, 0.8);
    });
  });
}

// ✅ Fixed helper functions
int _calculateCurrentStreak(List<HabitProgress> progressList) {
  if (progressList.isEmpty) return 0;

  // Sort by date descending (most recent first)
  final sortedProgress = [...progressList]
    ..sort((a, b) => b.date.compareTo(a.date));

  int streak = 0;
  // Count consecutive completed days from most recent
  for (final progress in sortedProgress) {
    if (progress.isCompleted) {
      streak++;
    } else {
      break; // Stop at first non-completed day
    }
  }
  return streak;
}

double _calculateCompletionRate(List<HabitProgress> progressList) {
  if (progressList.isEmpty) return 0.0;

  final completedDays = progressList.where((p) => p.isCompleted).length;
  return completedDays / progressList.length;
}
