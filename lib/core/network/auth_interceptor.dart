import 'package:dio/dio.dart';

import '../auth/jwt_token_handler.dart';
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
    final isConnected = await _networkInfo.isConnected;
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
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: DioExceptionType.badResponse,
            error: const UnauthorizedException(),
          ),
        );
      }
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
