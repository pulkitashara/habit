// lib/domain/entities/habit.dart
class Habit {
  final String id;
  final String name;
  final String description;
  final String category;
  final int targetCount;
  final String frequency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String color;
  final String icon;
  final int currentStreak;
  final int longestStreak;
  final double completionRate;

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.targetCount,
    required this.frequency,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.color,
    required this.icon,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completionRate = 0.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Habit && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
