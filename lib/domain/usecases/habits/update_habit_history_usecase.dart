import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../usecase.dart';

class UpdateHabitProgressUseCase implements UseCase<void, UpdateHabitProgressParams> {
  @override
  Future<Either<Failure, void>> call(UpdateHabitProgressParams params) async {
    return const Right(null);
  }
}

class UpdateHabitProgressParams {
  final String habitId;
  final DateTime date;
  final int completed;
  final bool isCompleted;

  UpdateHabitProgressParams({
    required this.habitId,
    required this.date,
    required this.completed,
    required this.isCompleted,
  });
}
