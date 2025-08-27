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

  // ✅ Add toJson method
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
    };
  }

  // ✅ Add fromJson factory
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
    );
  }
}
