// import 'package:dartz/dartz.dart';
// import '../../entities/habit.dart';
// import '../../../core/errors/failures.dart';
// import '../usecase.dart';
//
// class GetHabitsUseCase implements UseCase<List<Habit>, NoParams> {
//   @override
//   Future<Either<Failure, List<Habit>>> call(NoParams params) async {
//     // Mock habits data
//     final mockHabits = [
//       Habit(
//         id: '1',
//         name: 'Morning Exercise',
//         description: '30 minutes of exercise every morning',
//         category: 'fitness',
//         targetCount: 1,
//         frequency: 'daily',
//         createdAt: DateTime.now().subtract(const Duration(days: 7)),
//         updatedAt: DateTime.now(),
//         isActive: true,
//         color: '#FF6B6B',
//         icon: 'fitness_center',
//         currentStreak: 5,
//         longestStreak: 12,
//         completionRate: 0.8,
//       ),
//       Habit(
//         id: '2',
//         name: 'Drink Water',
//         description: 'Drink 8 glasses of water daily',
//         category: 'nutrition',
//         targetCount: 8,
//         frequency: 'daily',
//         createdAt: DateTime.now().subtract(const Duration(days: 5)),
//         updatedAt: DateTime.now(),
//         isActive: true,
//         color: '#4ECDC4',
//         icon: 'local_drink',
//         currentStreak: 3,
//         longestStreak: 7,
//         completionRate: 0.6,
//       ),
//     ];
//
//     return Right(mockHabits);
//   }
// }
