import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/habit_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/api_providers.dart';
import '../../widgets/dashboard/dashboard_header.dart';
import '../../widgets/habit/habit_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../routes/route_names.dart';
import '../../../data/datasources/local/hive_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

// Update your DashboardScreen class
class _DashboardScreenState extends ConsumerState<DashboardScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitProvider.notifier).loadHabits();
    });
  }

  @override
  void dispose() {
    // Remove observer to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ This detects when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload data when app resumes (handles date changes)
      ref.read(habitProvider.notifier).loadHabits();
    }
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

  void _dismissError() {
    ref.read(habitProvider.notifier).clearError();
  }

  void _showDebugDialog() {
    HiveService.debugPrintStorage();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🐛 Debug Storage Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hive Initialized: ${HiveService.isInitialized}'),
              Text('Habits Count: ${HiveService.getAllHabits().length}'),
              Text('Current Date: ${DateTime.now().toString().split(' ')[0]}'),
              Text('Habits Count: ${HiveService.getAllHabits().length}'),
              const SizedBox(height: 8),
              Text('Progress Count: ${HiveService.getAllHabits().map((h) => HiveService.getHabitProgress(h.id).length).fold(0, (a, b) => a + b)}'),
              const SizedBox(height: 16),
              const Text('Habits:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...HiveService.getAllHabits().map((habit) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text('• ${habit.name} (${habit.id})'),
              )),
              const SizedBox(height: 16),
              const Text('Recent Progress:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...HiveService.getAllHabits().take(3).expand((habit) {
                final progress = HiveService.getHabitProgress(habit.id).take(2);
                return progress.map((p) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('• ${habit.name}: ${p.date.day}/${p.date.month} ${p.isCompleted ? '✅' : '❌'}'),
                ));
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await HiveService.clearAllData();
              Navigator.of(context).pop();
              ref.read(habitProvider.notifier).loadHabits();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared!')),
              );
            },
            child: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
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
    final isOnline = ref.watch(networkStatusProvider);
    final apiError = ref.watch(apiErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Builder'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: _showDebugDialog,
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Storage',
          ),
          if (!isOnline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Offline', style: TextStyle(fontSize: 12, color: Colors.white)),
                ],
              ),
            ),
          if (habitState.isSyncing)
            Container(
              padding: const EdgeInsets.all(8),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  break;
                case 'settings':
                  break;
                case 'debug':
                  _showDebugDialog();
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(
                value: 'debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report, size: 16),
                    SizedBox(width: 8),
                    Text('Debug Storage'),
                  ],
                ),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHabits,
        child: CustomScrollView(
          slivers: [
            if (apiError != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(apiError, style: const TextStyle(color: Colors.red))),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => ref.read(apiErrorProvider.notifier).state = null,
                      ),
                    ],
                  ),
                ),
              ),
            if (habitState.error != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_outlined, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(habitState.error!, style: const TextStyle(color: Colors.orange))),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: _dismissError,
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: DashboardHeader(
                user: authState.user,
                totalHabits: habitState.habits.length,
                completedToday: _calculateCompletedToday(habitState.habits),
                currentStreak: _calculateMaxStreak(habitState.habits),
              ),
            ),
            if (habitState.isLoading)
              const SliverFillRemaining(
                child: Center(child: LoadingWidget()),
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
                      return Dismissible(
                        key: ValueKey(habit.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Habit?'),
                              content: const Text('Are you sure you want to delete this habit and all its progress?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                              ],
                            ),
                          );
                        },
                        background: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            color: Colors.red.withOpacity(0.12),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ),
                        onDismissed: (direction) {
                          final deletedHabit = habit;
                          ref.read(habitProvider.notifier).removeHabitFromState(deletedHabit.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${deletedHabit.name} deleted'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  await ref.read(habitProvider.notifier).addHabit(deletedHabit);
                                },
                              ),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                          Future.delayed(const Duration(seconds: 5), () async {
                            final exists = ref.read(habitProvider).habits.any((h) => h.id == deletedHabit.id);
                            if (!exists) {
                              await ref.read(habitProvider.notifier).deleteHabit(deletedHabit.id);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: HabitCard(
                            habit: habit,
                            onTap: () {
                              ref.read(habitProvider.notifier).loadHabitProgress(habit.id);
                              context.push('${RouteNames.habitDetail}/${habit.id}');
                            },
                            onToggleComplete: () async {
                              await ref.read(habitProvider.notifier).markHabitComplete(habit.id);
                            },
                          ),
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
        onPressed: () => context.push(RouteNames.addHabit),
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
        tooltip: 'Create a new habit',
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
            onPressed: () => context.push(RouteNames.addHabit),
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

  int _calculateCompletedToday(List<dynamic> habits) {
    final today = DateTime.now();
    int completedCount = 0;

    for (final habit in habits) {
      final todayProgress = HiveService.getTodayProgress(habit.id);
      if (todayProgress?.isCompleted == true) {
        completedCount++;
      }
    }

    return completedCount;
  }

  int _calculateMaxStreak(List<dynamic> habits) {
    if (habits.isEmpty) return 0;
    return habits.map((h) => h.currentStreak as int).reduce((a, b) => a > b ? a : b);
  }
}
