import 'package:equatable/equatable.dart';

/// Base failure class for domain layer error handling.
sealed class Failure extends Equatable {
  const Failure({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

final class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.code,
  });
}

final class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

final class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

final class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred',
    super.code,
  });
}
