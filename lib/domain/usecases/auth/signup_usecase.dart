import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../usecase.dart';

class SignupUseCase implements UseCase<void, SignupParams> {
  // Mock implementation
  @override
  Future<Either<Failure, void>> call(SignupParams params) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock success
    return const Right(null);
  }
}

class SignupParams {
  final String username;
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;

  SignupParams({
    required this.username,
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
  });
}
