// lib/presentation/widgets/habit/habit_card.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/habit.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/color_utils.dart'; // ✅ Add this import
import '../../../data/datasources/local/hive_service.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback? onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onTap,
    required this.onToggleComplete,
    this.onDelete,
  });

  // ✅ NEW: Get the actual custom color or fallback to category color
  Color _getHabitColor() {
    if (habit.color.isNotEmpty) {
      return ColorUtils.parseHexColor(habit.color);
    }
    return ColorUtils.getCategoryFallbackColor(habit.category);
  }

  IconData _getCategoryIcon() {
    switch (habit.category.toLowerCase()) {
      case 'fitness':
        return Icons.fitness_center;
      case 'nutrition':
        return Icons.restaurant;
      case 'mindfulness':
        return Icons.self_improvement;
      case 'productivity':
        return Icons.work;
      case 'social':
        return Icons.people;
      default:
        return Icons.psychology;
    }
  }

  bool _isCompletedToday() {
    final todayProgress = HiveService.getTodayProgress(habit.id);
    return todayProgress?.isCompleted == true;
  }

  double _getCurrentProgress() {
    final todayProgress = HiveService.getTodayProgress(habit.id);
    if (todayProgress?.isCompleted == true) {
      return 1.0;
    }

    if (todayProgress != null && todayProgress.completed > 0) {
      return todayProgress.completed / todayProgress.target;
    }

    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Use custom habit color instead of category color
    final habitColor = _getHabitColor();
    final isCompletedToday = _isCompletedToday();
    final currentProgress = _getCurrentProgress();

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      // ✅ FIXED: Use custom habit color
                      color: habitColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      // ✅ FIXED: Use custom habit color
                      color: habitColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          habit.category.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            // ✅ FIXED: Use custom habit color
                            color: habitColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onToggleComplete,
                    icon: Icon(
                      Icons.check_circle,
                      color: isCompletedToday
                          ? AppColors.success
                          : Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Today\'s Progress',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${(currentProgress * 100).toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                // ✅ FIXED: Use custom habit color
                                color: habitColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: currentProgress,
                            backgroundColor: Colors.grey.shade200,
                            // ✅ FIXED: Use custom habit color
                            valueColor: AlwaysStoppedAnimation<Color>(habitColor),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: AppColors.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.currentStreak}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'streak',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
