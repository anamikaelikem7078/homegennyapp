import 'failures.dart';

/// Application-level exceptions mapped to [Failure] objects.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  Failure toFailure();
}

final class ServerException extends AppException {
  const ServerException(super.message, {super.code});

  @override
  Failure toFailure() => ServerFailure(message: message, code: code);
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);

  @override
  Failure toFailure() => NetworkFailure(message: message, code: code);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Session expired. Please login again.',
  ]);

  @override
  Failure toFailure() => AuthFailure(message: message, code: code);
}

final class TokenRefreshException extends AppException {
  const TokenRefreshException([
    super.message = 'Unable to refresh session.',
  ]);

  @override
  Failure toFailure() => AuthFailure(message: message, code: code);
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});

  @override
  Failure toFailure() => ValidationFailure(message: message, code: code);
}

final class CacheException extends AppException {
  const CacheException(super.message, {super.code});

  @override
  Failure toFailure() => CacheFailure(message: message, code: code);
}

final class VersionException extends AppException {
  const VersionException(super.message, {super.code});

  @override
  Failure toFailure() => ServerFailure(message: message, code: code);
}
