import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_progress.dart';

abstract class ApiService {
  // Authentication
  Future<Map<String, dynamic>> login(String username, String password);
  Future<Map<String, dynamic>> signup(Map<String, dynamic> userData);
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
  Future<void> logout(String token);

  // Habits
  Future<List<Map<String, dynamic>>> getHabits(String token);
  Future<Map<String, dynamic>> createHabit(String token, Map<String, dynamic> habitData);
  Future<Map<String, dynamic>> updateHabit(String token, String habitId, Map<String, dynamic> habitData);
  Future<void> deleteHabit(String token, String habitId);

  // Progress
  Future<void> updateHabitProgress(String token, String habitId, Map<String, dynamic> progressData);
  Future<List<Map<String, dynamic>>> getHabitProgress(String token, String habitId);

  // Sync
  Future<Map<String, dynamic>> syncData(String token, Map<String, dynamic> localData);
}
