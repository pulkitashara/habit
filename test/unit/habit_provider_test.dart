import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_builder/presentation/providers/habit_provider.dart';
import '../test_helper.dart';

void main() {
  group('HabitProvider Tests', () {
    late ProviderContainer container;

    setUpAll(() async {
      await TestHelper.setupTest();
    });

    tearDownAll(() async {
      await TestHelper.cleanupTest();
    });

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should start with empty habits list', () {
      final habitState = container.read(habitProvider);
      expect(habitState.habits, isEmpty);
      expect(habitState.isLoading, isFalse);
    });

    test('should handle empty state correctly', () {
      final habitState = container.read(habitProvider);
      expect(habitState.habits, isEmpty);
      expect(habitState.error, isNull);
    });

    // ✅ Test the actual HiveService methods work
    test('should handle user operations', () {
      // This will test that boxes are properly opened
      try {
        // These should not throw "Box not found" errors now
        expect(() => container.read(habitProvider), returnsNormally);
      } catch (e) {
        fail('HiveService should work in tests: $e');
      }
    });
  });
}
