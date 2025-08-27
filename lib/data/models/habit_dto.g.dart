// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HabitDto _$HabitDtoFromJson(Map<String, dynamic> json) => HabitDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      targetCount: (json['targetCount'] as num).toInt(),
      frequency: json['frequency'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      isActive: json['isActive'] as bool,
      color: json['color'] as String,
      icon: json['icon'] as String,
      currentStreak: (json['currentStreak'] as num).toInt(),
      longestStreak: (json['longestStreak'] as num).toInt(),
      completionRate: (json['completionRate'] as num).toDouble(),
    );

Map<String, dynamic> _$HabitDtoToJson(HabitDto instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'targetCount': instance.targetCount,
      'frequency': instance.frequency,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'isActive': instance.isActive,
      'color': instance.color,
      'icon': instance.icon,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'completionRate': instance.completionRate,
    };
