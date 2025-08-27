abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiException extends AppException {
  ApiException(String message, [int? statusCode]) : super(message, statusCode);
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message);
}

class AuthException extends AppException {
  AuthException(String message) : super(message, 401);
}

class ServerException extends AppException {
  ServerException(String message) : super(message, 500);
}

class TimeoutException extends AppException {
  TimeoutException() : super('Request timeout. Please try again.');
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message, 400);
}
