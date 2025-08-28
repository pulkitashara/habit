// lib/presentation/widgets/habit/habit_card.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/habit.dart';
import '../../../core/theme/colors.dart';

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

  Color _getCategoryColor() {
    switch (habit.category.toLowerCase()) {
      case 'fitness':
        return AppColors.fitness;
      case 'nutrition':
        return AppColors.nutrition;
      case 'mindfulness':
        return AppColors.mindfulness;
      case 'productivity':
        return AppColors.productivity;
      case 'social':
        return AppColors.social;
      default:
        return AppColors.primary;
    }
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

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();

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
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: categoryColor,
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
                            color: categoryColor,
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
                      color: habit.completionRate > 0
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
                              'Progress',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${(habit.completionRate * 100).toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: habit.completionRate,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
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
