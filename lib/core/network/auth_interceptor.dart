import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/jwt_token_handler.dart';
import '../auth/session_event_bus.dart';
import '../auth/token_refresh_service.dart';
import '../constants/api_constants.dart';
import '../exceptions/app_exceptions.dart';
import '../network/network_info.dart';

/// Attaches JWT tokens and handles 401 refresh flow.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required JwtTokenHandler tokenHandler,
    required TokenRefreshService refreshService,
    required NetworkInfo networkInfo,
  })  : _tokenHandler = tokenHandler,
        _refreshService = refreshService,
        _networkInfo = networkInfo;

  final JwtTokenHandler _tokenHandler;
  final TokenRefreshService _refreshService;
  final NetworkInfo _networkInfo;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // `_networkInfo.isConnected` (connectivity_plus) and secure-storage
    // reads below are platform channel calls that can throw on some
    // platforms (observed as opaque "OperationError"/DioExceptionType.unknown
    // failures on Flutter Web — connectivity_plus's web implementation and
    // flutter_secure_storage's web WebCrypto path are both known to be
    // flakier there than on mobile). An uncaught exception here previously
    // meant the request was never dispatched at all — no HTTP call, no
    // response, just a swallowed opaque error — which looked identical to a
    // real network failure but wasn't one. None of this should ever block
    // dispatching the actual request, so every step degrades instead of
    // throwing: connectivity check failure proceeds optimistically (a truly
    // offline device will still fail at the real network layer, and Dio
    // reports that clearly), token refresh/read failure proceeds
    // unauthenticated (the real 401 handler in `onError` takes over).
    bool isConnected = true;
    try {
      isConnected = await _networkInfo.isConnected;
    } catch (e) {
      if (kDebugMode) debugPrint('AuthInterceptor: connectivity check threw, proceeding anyway: $e');
      isConnected = true;
    }
    if (!isConnected) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const NetworkException(),
        ),
      );
    }

    final isAuthEndpoint = _isAuthEndpoint(options.path);
    if (!isAuthEndpoint) {
      try {
        if (await _tokenHandler.shouldRefreshToken()) {
          try {
            await _refreshService.refreshAccessToken();
          } on TokenRefreshException {
            // Proceed with existing token; 401 handler will redirect.
          }
        }

        final token = await _tokenHandler.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers[ApiConstants.headerAuthorization] =
              '${ApiConstants.bearerPrefix}$token';
        }
      } catch (e) {
        // Fall through and send the request without a token rather than
        // never sending it at all.
        if (kDebugMode) debugPrint('AuthInterceptor: token read/refresh threw, sending request unauthenticated: $e');
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        !_isAuthEndpoint(err.requestOptions.path)) {
      try {
        final newToken = await _refreshService.refreshAccessToken();
        if (newToken != null) {
          final options = err.requestOptions;
          options.headers[ApiConstants.headerAuthorization] =
              '${ApiConstants.bearerPrefix}$newToken';

          final dio = Dio(
            BaseOptions(
              baseUrl: options.baseUrl,
              connectTimeout: options.connectTimeout,
              receiveTimeout: options.receiveTimeout,
            ),
          );

          final response = await dio.fetch<dynamic>(options);
          return handler.resolve(response);
        }
      } on TokenRefreshException {
        SessionEventBus.instance.notifySessionExpired();
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: DioExceptionType.badResponse,
            error: const UnauthorizedException(),
          ),
        );
      }

      // Refresh returned no token without throwing — the session is dead
      // just the same, so treat it identically to the exception branch
      // above instead of silently forwarding the original 401.
      SessionEventBus.instance.notifySessionExpired();
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: DioExceptionType.badResponse,
          error: const UnauthorizedException(),
        ),
      );
    }

    handler.next(err);
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/verify-otp') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/forgot-password');
  }
}
