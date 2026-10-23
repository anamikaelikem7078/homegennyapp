import 'package:equatable/equatable.dart';

/// Base failure class for domain layer error handling.
sealed class Failure extends Equatable {
  const Failure({
    required this.message,
    this.code,
    this.errorCode,
    this.missing = const [],
  });

  final String message;

  /// HTTP status as a string ('400', '403', …) for API errors.
  final String? code;

  /// Machine-readable `message.error` from the API body, e.g.
  /// `PROFILE_INCOMPLETE`. Null when the server sent none.
  final String? errorCode;

  /// `message.missing` — the profile fields still to fill, sent with
  /// `PROFILE_INCOMPLETE`.
  final List<String> missing;

  bool get isProfileIncomplete => errorCode == 'PROFILE_INCOMPLETE';

  @override
  List<Object?> get props => [message, code, errorCode, missing];
}

final class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code, super.errorCode, super.missing});
}

final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.code,
  });
}

final class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code, super.errorCode, super.missing});
}

final class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code, super.errorCode, super.missing});
}

final class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred',
    super.code,
  });
}
