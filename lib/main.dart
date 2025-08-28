import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'presentation/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'data/models/habit_model.dart';
import 'data/models/habit_progress_model.dart';
import 'data/models/user_model.dart';
import 'data/datasources/local/hive_service.dart'; // ✅ Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Hive using HiveService (prevents duplicate initialization)
  await HiveService.initializeHive();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Habit Builder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
