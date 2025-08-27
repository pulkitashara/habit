import 'package:flutter_test/flutter_test.dart';
import 'package:habit_builder/data/services/mock_api_service.dart';
import 'package:habit_builder/core/exceptions/api_exception.dart';

void main() {
  group('MockApiService', () {
    late MockApiService apiService;

    setUp(() {
      apiService = MockApiService();
    });

    group('login', () {
      test('should return token for valid credentials', () async {
        final result = await apiService.login('test@example.com', 'password123');

        expect(result['token'], isNotNull);
        expect(result['user']['email'], equals('test@example.com'));
        expect(result['expiresIn'], equals(3600));
      });

      test('should throw AuthException for invalid credentials', () async {
        expect(
              () => apiService.login('wrong@email.com', 'wrongpassword'),
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw ValidationException for empty credentials', () async {
        expect(
              () => apiService.login('', ''),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('getHabits', () {
      test('should return list of habits for valid token', () async {
        final loginResult = await apiService.login('test@example.com', 'password123');
        final habits = await apiService.getHabits(loginResult['token']);

        expect(habits, isA<List>());
        expect(habits.length, greaterThan(0));
        expect(habits.first['name'], isNotNull);
      });

      test('should throw AuthException for invalid token', () async {
        expect(
              () => apiService.getHabits('invalid_token'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('createHabit', () {
      test('should create habit and return with server ID', () async {
        final loginResult = await apiService.login('test@example.com', 'password123');

        final habitData = {
          'name': 'Test Habit',
          'description': 'Test Description',
          'category': 'fitness',
          'targetCount': 1,
          'frequency': 'daily',
        };

        final result = await apiService.createHabit(loginResult['token'], habitData);

        expect(result['id'], isNotNull);
        expect(result['name'], equals('Test Habit'));
        expect(result['createdAt'], isNotNull);
      });

      test('should throw ValidationException for invalid habit data', () async {
        final loginResult = await apiService.login('test@example.com', 'password123');

        expect(
              () => apiService.createHabit(loginResult['token'], {}),
          throwsA(isA<ValidationException>()),
        );
      });
    });
  });
}
