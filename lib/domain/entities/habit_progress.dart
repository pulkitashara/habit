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
  final String userId; // ✅ Added userId field

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
    required this.userId, // ✅ Added to constructor
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date.toIso8601String(),
      'completed': completed,
      'target': target,
      'isCompleted': isCompleted,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'synced': synced,
      'userId': userId, // ✅ Added to JSON
    };
  }

  static HabitProgress fromJson(Map<String, dynamic> json) {
    return HabitProgress(
      id: json['id'],
      habitId: json['habitId'],
      date: DateTime.parse(json['date']),
      completed: json['completed'],
      target: json['target'],
      isCompleted: json['isCompleted'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      synced: json['synced'] ?? false,
      userId: json['userId'], // ✅ Added from JSON
    );
  }
}
