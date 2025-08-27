import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/habit.dart';

part 'habit_dto.g.dart';

@JsonSerializable()
class HabitDto {
  final String id;
  final String name;
  final String description;
  final String category;
  final int targetCount;
  final String frequency;
  final String createdAt;
  final String updatedAt;
  final bool isActive;
  final String color;
  final String icon;
  final int currentStreak;
  final int longestStreak;
  final double completionRate;

  HabitDto({
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
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
  });

  factory HabitDto.fromJson(Map<String, dynamic> json) =>
      _$HabitDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HabitDtoToJson(this);

  Habit toEntity() {
    return Habit(
      id: id,
      name: name,
      description: description,
      category: category,
      targetCount: targetCount,
      frequency: frequency,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      isActive: isActive,
      color: color,
      icon: icon,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      completionRate: completionRate,
    );
  }

  static HabitDto fromEntity(Habit habit) {
    return HabitDto(
      id: habit.id,
      name: habit.name,
      description: habit.description,
      category: habit.category,
      targetCount: habit.targetCount,
      frequency: habit.frequency,
      createdAt: habit.createdAt.toIso8601String(),
      updatedAt: habit.updatedAt.toIso8601String(),
      isActive: habit.isActive,
      color: habit.color,
      icon: habit.icon,
      currentStreak: habit.currentStreak,
      longestStreak: habit.longestStreak,
      completionRate: habit.completionRate,
    );
  }
}
