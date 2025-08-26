import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/hive_service.dart';

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false) {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final isDarkMode = HiveService.getSetting<bool>('isDarkMode') ?? false;
    state = isDarkMode;
  }

  Future<void> toggleTheme() async {
    state = !state;
    await HiveService.saveSetting('isDarkMode', state);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});
