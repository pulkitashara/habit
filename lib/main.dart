import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_builder/presentation/providers/auth_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'presentation/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'data/models/habit_model.dart';
import 'data/models/habit_progress_model.dart';
import 'data/models/user_model.dart';
import 'data/datasources/local/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ Initialize Hive first
    await HiveService.initializeHive();
    print('✅ Hive initialized successfully');
  } catch (e) {
    print('❌ Hive initialization failed: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // ✅ Initialize auth after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initializeAuth();
    });
  }
  @override
  Widget build(BuildContext context) {
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

