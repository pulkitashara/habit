// lib/presentation/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/habit_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/dashboard/dashboard_header.dart';
import '../../widgets/habit/habit_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../routes/route_names.dart';
import '../../../core/theme/colors.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load habits when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitProvider.notifier).loadHabits();
    });
  }

  Future<void> _refreshHabits() async {
    await ref.read(habitProvider.notifier).loadHabits();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
              context.go(RouteNames.login);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitState = ref.watch(habitProvider);
    final authState = ref.watch(authProvider);
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Builder'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                // TODO: Navigate to profile
                  break;
                case 'settings':
                // TODO: Navigate to settings
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHabits,
        child: CustomScrollView(
          slivers: [
            // Dashboard Header
            SliverToBoxAdapter(
              child: DashboardHeader(
                user: authState.user,
                totalHabits: habitState.habits.length,
                completedToday: habitState.habits
                    .where((habit) => habit.completionRate > 0)
                    .length,
                currentStreak: habitState.habits.isNotEmpty
                    ? habitState.habits
                    .map((h) => h.currentStreak)
                    .reduce((a, b) => a > b ? a : b)
                    : 0,
              ),
            ),

            // Habits List
            if (habitState.isLoading)
              const SliverFillRemaining(
                child: Center(child: LoadingWidget()),
              )
            else if (habitState.error != null)
              SliverFillRemaining(
                child: CustomErrorWidget(
                  message: habitState.error!,
                  onRetry: _refreshHabits,
                ),
              )
            else if (habitState.habits.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final habit = habitState.habits[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: HabitCard(
                            habit: habit,
                            onTap: () => context.push(
                              '${RouteNames.habitDetail}/${habit.id}',
                            ),
                            onToggleComplete: () => ref
                                .read(habitProvider.notifier)
                                .markHabitComplete(habit.id),
                          ),
                        );
                      },
                      childCount: habitState.habits.length,
                    ),
                  ),
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.createHabit),
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 96,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Start Building Habits',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first habit and begin your journey to a better you.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.push(RouteNames.createHabit),
            icon: const Icon(Icons.add),
            label: const Text('Create First Habit'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
