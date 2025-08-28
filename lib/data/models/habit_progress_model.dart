import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/habit_progress.dart';

part 'habit_progress_model.g.dart';

@HiveType(typeId: 1)
class HabitProgressModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String habitId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final int completed;

  @HiveField(4)
  final int target;

  @HiveField(5)
  final bool isCompleted;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final bool synced;

  HabitProgressModel({
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

  HabitProgress toEntity() {
    return HabitProgress(
      id: id,
      habitId: habitId,
      date: date,
      completed: completed,
      target: target,
      isCompleted: isCompleted,
      notes: notes,
      createdAt: createdAt,
      synced: synced,
    );
  }

  factory HabitProgressModel.fromEntity(HabitProgress entity) {
    return HabitProgressModel(
      id: entity.id,
      habitId: entity.habitId,
      date: entity.date,
      completed: entity.completed,
      target: entity.target,
      isCompleted: entity.isCompleted,
      notes: entity.notes,
      createdAt: entity.createdAt,
      synced: entity.synced,
    );
  }
}
