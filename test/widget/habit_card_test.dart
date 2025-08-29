import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_builder/presentation/widgets/habit/habit_card.dart';
import 'package:habit_builder/domain/entities/habit.dart';
import '../test_helper.dart';

void main() {
  group('HabitCard Widget Tests', () {
    late Habit testHabit;

    setUpAll(() async {
      await TestHelper.setupTest();
    });

    tearDownAll(() async {
      await TestHelper.cleanupTest();
    });

    setUp(() {
      testHabit = Habit(
        id: 'test_habit',
        name: 'Morning Exercise',
        description: '30 minutes workout',
        category: 'fitness',
        targetCount: 1,
        frequency: 'daily',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        color: '#FF6B6B',
        icon: 'fitness_center',
        currentStreak: 5,
        longestStreak: 10,
        completionRate: 0.8,
        userId: 'user123',
      );
    });

    testWidgets('should display habit name and category', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HabitCard(
                habit: testHabit,
                onTap: () {},
                onToggleComplete: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Morning Exercise'), findsOneWidget);
      expect(find.text('FITNESS'), findsOneWidget);
    });

    testWidgets('should display current streak', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HabitCard(
                habit: testHabit,
                onTap: () {},
                onToggleComplete: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('streak'), findsOneWidget);
    });

    testWidgets('should call onTap when card is tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HabitCard(
                habit: testHabit,
                onTap: () => wasTapped = true,
                onToggleComplete: () {},
              ),
            ),
          ),
        ),
      );

      // ✅ Use the specific key instead of generic InkWell finder
      await tester.tap(find.byKey(const Key('habit_card_tap_area')));
      await tester.pump();

      expect(wasTapped, isTrue);
    });
  });
}
