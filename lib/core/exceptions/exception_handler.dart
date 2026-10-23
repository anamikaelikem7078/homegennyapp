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

    final errorCode = extractErrorCode(data);
    final missing = extractMissing(data);

    switch (statusCode) {
      case 400:
      case 409:
      case 422:
        return ValidationFailure(
          message: message,
          code: '$statusCode',
          errorCode: errorCode,
          missing: missing,
        );
      case 401:
      case 403:
        return AuthFailure(
          message: message,
          code: '$statusCode',
          errorCode: errorCode,
          missing: missing,
        );
      case 429:
        // OTP send + verify share one 10/min-per-IP bucket — surface a fixed,
        // friendly message rather than whatever text the throttle guard sent,
        // and never auto-retry on this.
        return const ValidationFailure(
          message: 'Too many attempts, try again in a minute',
          code: '429',
        );
      default:
        return ServerFailure(
          message: message,
          code: '$statusCode',
          errorCode: errorCode,
          missing: missing,
        );
    }
  }

  /// `message.error` from `{ statusCode, message: { message, error, missing } }`
  /// — only when it is a machine code (e.g. `PROFILE_INCOMPLETE`), not
  /// Nest's generic "Bad Request"/"Forbidden" labels.
  static String? extractErrorCode(dynamic data) {
    if (data is! Map) return null;
    final inner = data['message'];
    final raw = inner is Map ? inner['error'] : data['error'];
    if (raw is! String || !RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(raw)) return null;
    return raw;
  }

  /// `message.missing` (or a top-level `missing`) as a string list.
  static List<String> extractMissing(dynamic data) {
    if (data is! Map) return const [];
    final inner = data['message'];
    final raw = inner is Map ? inner['missing'] : data['missing'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
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
