import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'app_exceptions.dart';
import 'failures.dart';

/// Central exception handler for API and runtime errors.
abstract final class ExceptionHandler {
  static Failure handle(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode && stackTrace != null) {
      debugPrint('ExceptionHandler: $error\n$stackTrace');
    }

    if (error is AppException) {
      return error.toFailure();
    }

    if (error is DioException) {
      return _handleDioException(error);
    }

    if (error is Failure) {
      return error;
    }

    return UnknownFailure(message: error.toString());
  }

  static Failure _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(message: 'Connection timed out');
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        return _handleBadResponse(error);
      case DioExceptionType.cancel:
        return const UnknownFailure(message: 'Request cancelled');
      case DioExceptionType.badCertificate:
        return const NetworkFailure(message: 'Invalid SSL certificate');
      case DioExceptionType.transformTimeout:
        return const NetworkFailure(message: 'Response transform timed out');
      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          return const NetworkFailure();
        }
        return UnknownFailure(message: error.message ?? 'Network error');
    }
  }

  static Failure _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final message = _extractMessage(data) ?? 'Server error occurred';

    switch (statusCode) {
      case 400:
        return ValidationFailure(message: message, code: '$statusCode');
      case 401:
        return AuthFailure(message: message, code: '$statusCode');
      case 403:
        return AuthFailure(
          message: message,
          code: '$statusCode',
        );
      case 404:
        return ServerFailure(message: message, code: '$statusCode');
      case 422:
        return ValidationFailure(message: message, code: '$statusCode');
      case 500:
      case 502:
      case 503:
        return ServerFailure(message: message, code: '$statusCode');
      default:
        return ServerFailure(message: message, code: '$statusCode');
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is List) {
      final parts = data.map(_extractMessage).whereType<String>().toList();
      return parts.isEmpty ? null : parts.join('\n');
    }
    if (data is Map) {
      return _extractMessage(data['message']) ??
          _extractMessage(data['error']) ??
          _extractMessage(data['detail']);
    }
    return null;
  }

  static String userMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => failure.message,
      AuthFailure() => failure.message,
      ValidationFailure() => failure.message,
      ServerFailure() => failure.message,
      CacheFailure() => failure.message,
      UnknownFailure() => failure.message,
    };
  }
}
