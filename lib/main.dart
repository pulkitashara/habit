import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'presentation/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'data/models/habit_model.dart';
import 'data/models/habit_progress_model.dart';
import 'data/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters (after running build_runner)
  Hive.registerAdapter(HabitModelAdapter());
  Hive.registerAdapter(HabitProgressModelAdapter());
  Hive.registerAdapter(UserModelAdapter());

  // Open boxes
  await Hive.openBox<HabitModel>('habits');
  await Hive.openBox<HabitProgressModel>('progress');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider); // ✅ Watch the router provider

    return MaterialApp.router(
      title: 'Habit Builder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router, // ✅ Pass the router instance, not a function
    );
  }
}
