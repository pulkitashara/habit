// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitProgressModelAdapter extends TypeAdapter<HabitProgressModel> {
  @override
  final int typeId = 1;

  @override
  HabitProgressModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitProgressModel(
      id: fields[0] as String,
      habitId: fields[1] as String,
      date: fields[2] as DateTime,
      completed: fields[3] as int,
      target: fields[4] as int,
      isCompleted: fields[5] as bool,
      notes: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      synced: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HabitProgressModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.habitId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.completed)
      ..writeByte(4)
      ..write(obj.target)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitProgressModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HabitProgressModel _$HabitProgressModelFromJson(Map<String, dynamic> json) =>
    HabitProgressModel(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      date: DateTime.parse(json['date'] as String),
      completed: (json['completed'] as num).toInt(),
      target: (json['target'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      synced: json['synced'] as bool? ?? false,
    );

Map<String, dynamic> _$HabitProgressModelToJson(HabitProgressModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'habitId': instance.habitId,
      'date': instance.date.toIso8601String(),
      'completed': instance.completed,
      'target': instance.target,
      'isCompleted': instance.isCompleted,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'synced': instance.synced,
    };
