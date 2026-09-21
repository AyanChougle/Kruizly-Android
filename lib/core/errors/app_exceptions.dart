class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const AppException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = '''Network connection error. Please check your internet.''',
  ]);
}

class AuthException extends AppException {
  const AuthException(super.message, {super.statusCode});
}

class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode, super.details});
}
