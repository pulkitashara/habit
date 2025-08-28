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
  final String userId;

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
    required this.userId,
  });

  // ✅ Add copyWith method
  Habit copyWith({
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
    String? userId,
  }) {
    return Habit(
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
      userId: userId ?? this.userId,
    );
  }

  // ✅ Add toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'targetCount': targetCount,
      'frequency': frequency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'color': color,
      'icon': icon,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'completionRate': completionRate,
      'userId': userId,
    };
  }

  // ✅ Add fromJson factory
  static Habit fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      category: json['category'],
      targetCount: json['targetCount'],
      frequency: json['frequency'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'] ?? true,
      color: json['color'],
      icon: json['icon'],
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      completionRate: json['completionRate']?.toDouble() ?? 0.0,
      userId: json['userId'],
    );
  }
}
