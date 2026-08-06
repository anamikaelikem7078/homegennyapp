import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';

/// Logs HTTP requests and responses in debug mode.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.d(
        '→ ${options.method} ${options.uri}\n'
        'Headers: ${options.headers}\n'
        'Data: ${options.data}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.d(
        '← ${response.statusCode} ${response.requestOptions.uri}\n'
        'Data: ${response.data}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.e(
        '✕ ${err.requestOptions.method} ${err.requestOptions.uri}\n'
        'Status: ${err.response?.statusCode}\n'
        'Message: ${err.message}\n'
        'Data: ${err.response?.data}',
      );
    }
    handler.next(err);
  }
}
