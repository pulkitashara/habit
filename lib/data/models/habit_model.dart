import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/habit.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class HabitModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final int targetCount;

  @HiveField(5)
  final String frequency;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final bool isActive;

  @HiveField(9)
  final String color;

  @HiveField(10)
  final String icon;

  @HiveField(11)
  final int currentStreak;

  @HiveField(12)
  final int longestStreak;

  @HiveField(13)
  final double completionRate;

  @HiveField(14)
  final String userId;

  HabitModel({
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

  factory HabitModel.fromJson(Map<String, dynamic> json) =>
      _$HabitModelFromJson(json);

  Map<String, dynamic> toJson() => _$HabitModelToJson(this);

  Habit toEntity() {
    return Habit(
      id: id,
      name: name,
      description: description,
      category: category,
      targetCount: targetCount,
      frequency: frequency,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
      color: color,
      icon: icon,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      completionRate: completionRate,
    );
  }

  static HabitModel fromEntity(Habit habit) {
    return HabitModel(
      id: habit.id,
      name: habit.name,
      description: habit.description,
      category: habit.category,
      targetCount: habit.targetCount,
      frequency: habit.frequency,
      createdAt: habit.createdAt,
      updatedAt: habit.updatedAt,
      isActive: habit.isActive,
      color: habit.color,
      icon: habit.icon,
      currentStreak: habit.currentStreak,
      longestStreak: habit.longestStreak,
      completionRate: habit.completionRate,
    );  }

  HabitModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? targetCount,
    String? frequency,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? color,
    String? icon,
    int? currentStreak,
    int? longestStreak,
    double? completionRate,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      targetCount: targetCount ?? this.targetCount,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      completionRate: completionRate ?? this.completionRate,
    );
  }
}
