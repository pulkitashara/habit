import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../usecase.dart';

class LogoutUseCase implements UseCase<void, NoParams> {
  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    // Mock logout
    return const Right(null);
  }
}
