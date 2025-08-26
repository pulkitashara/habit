import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/habit_progress.dart';

part 'habit_progress_model.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
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

  factory HabitProgressModel.fromJson(Map<String, dynamic> json) =>
      _$HabitProgressModelFromJson(json);

  Map<String, dynamic> toJson() => _$HabitProgressModelToJson(this);

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

  static HabitProgressModel fromEntity(HabitProgress progress) {
    return HabitProgressModel(
      id: progress.id,
      habitId: progress.habitId,
      date: progress.date,
      completed: progress.completed,
      target: progress.target,
      isCompleted: progress.isCompleted,
      notes: progress.notes,
      createdAt: progress.createdAt,
      synced: progress.synced,
    );
  }

  HabitProgressModel copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    int? completed,
    int? target,
    bool? isCompleted,
    String? notes,
    DateTime? createdAt,
    bool? synced,
  }) {
    return HabitProgressModel(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      target: target ?? this.target,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }
}
