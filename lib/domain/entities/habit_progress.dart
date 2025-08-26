// lib/domain/entities/habit_progress.dart
class HabitProgress {
  final String id;
  final String habitId;
  final DateTime date;
  final int completed;
  final int target;
  final bool isCompleted;
  final String? notes;
  final DateTime createdAt;
  final bool synced;

  HabitProgress({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    required this.target,
    required this.isCompleted,
    this.notes,
    required this.createdAt,
    this.synced = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is HabitProgress &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}
