// lib/presentation/screens/habit/habit_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/habit/progress_chart.dart';
import '../../widgets/habit/streak_widget.dart';
import '../../widgets/habit/calendar_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/date_utils.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final String habitId;

  const HabitDetailScreen({
    super.key,
    required this.habitId,
  });

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load habit details and progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitProvider.notifier).loadHabitProgress(widget.habitId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    final habitState = ref.watch(habitProvider);
    final habit = habitState.habits.firstWhere(
          (h) => h.id == widget.habitId,
      orElse: () => throw Exception('Habit not found'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        backgroundColor: _getCategoryColor(habit.category).withValues(alpha: 0.1),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                // TODO: Navigate to edit habit
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Habit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Habit')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
            Tab(text: 'History', icon: Icon(Icons.calendar_month)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(habit),
          _buildProgressTab(habit, habitState),
          _buildHistoryTab(habit, habitState),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: CustomButton(
            text: _getTodayButtonText(habit),
            onPressed: () => _markHabitComplete(habit),
            backgroundColor: _getCategoryColor(habit.category),
            isEnabled: !_isCompletedToday(habit),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(habit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Habit Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(habit.category).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(habit.category),
                          color: _getCategoryColor(habit.category),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              habit.category.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getCategoryColor(habit.category),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (habit.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      habit.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildInfoRow('Target', '${habit.targetCount} times ${habit.frequency}'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Created', DateUtilsHelper.formatDate(habit.createdAt)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Current Streak',
                  '${habit.currentStreak}',
                  'days',
                  Icons.local_fire_department,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Best Streak',
                  '${habit.longestStreak}',
                  'days',
                  Icons.emoji_events,
                  AppColors.warning,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Completion Rate',
                  '${(habit.completionRate * 100).toInt()}',
                  '%',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Days',
                  '${DateTime.now().difference(habit.createdAt).inDays + 1}',
                  'days',
                  Icons.calendar_today,
                  AppColors.info,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Streak Widget
          StreakWidget(
            currentStreak: habit.currentStreak,
            longestStreak: habit.longestStreak,
            color: _getCategoryColor(habit.category),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab(habit, habitState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Chart',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 300,
                child: habitState.isLoadingProgress
                    ? const Center(child: LoadingWidget())
                    : ProgressChart(
                  habitId: habit.id,
                  progressData: habitState.habitProgress[habit.id] ?? [],
                  color: _getCategoryColor(habit.category),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Weekly Summary
          Text(
            'This Week',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildWeeklySummary(habit, habitState),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(habit, habitState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Habit Calendar',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CalendarWidget(
                habitId: habit.id,
                progressData: habitState.habitProgress[habit.id] ?? [],
                onDaySelected: (date) {
                  // TODO: Show day details
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildRecentActivity(habit, habitState),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      String subtitle,
      IconData icon,
      Color color,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary(habit, habitState) {
    // TODO: Implement weekly summary
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Weekly summary coming soon...'),
      ),
    );
  }

  Widget _buildRecentActivity(habit, habitState) {
    final recentProgress = (habitState.habitProgress[habit.id] ?? [])
        .take(7)
        .toList();

    if (recentProgress.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No recent activity'),
        ),
      );
    }

    return Column(
      children: recentProgress.map<Widget>((progress) {  // ✅ Added <Widget> type
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: progress.isCompleted
                  ? AppColors.success.withValues(alpha: 0.2)  // Fixed withOpacity
                  : AppColors.error.withValues(alpha: 0.2),
              child: Icon(
                progress.isCompleted ? Icons.check : Icons.close,
                color: progress.isCompleted ? AppColors.success : AppColors.error,
              ),
            ),
            title: Text(DateUtilsHelper.formatDate(progress.date)),
            subtitle: Text(
              progress.isCompleted
                  ? 'Completed (${progress.completed}/${progress.target})'
                  : 'Missed',
            ),
            trailing: progress.notes?.isNotEmpty == true
                ? const Icon(Icons.note)
                : null,
          ),
        );
      }).toList(),  // ✅ This now returns List<Widget> properly
    );
  }


  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
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

  String _getTodayButtonText(habit) {
    if (_isCompletedToday(habit)) {
      return 'Completed Today ✓';
    }
    return 'Mark Complete';
  }

  bool _isCompletedToday(habit) {
    // TODO: Implement check for today's completion
    return false;
  }

  void _markHabitComplete(habit) {
    ref.read(habitProvider.notifier).markHabitComplete(habit.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${habit.name} marked as complete!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: const Text(
          'Are you sure you want to delete this habit? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(habitProvider.notifier).deleteHabit(widget.habitId);
              context.pop();
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
    );
  }
}
