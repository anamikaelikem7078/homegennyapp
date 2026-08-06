import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';
import '../exceptions/app_exceptions.dart';
import '../storage/secure_storage_service.dart';
import '../utils/logger.dart';
import 'jwt_token_handler.dart';

/// Handles automatic JWT refresh when access token expires.
class TokenRefreshService {
  TokenRefreshService({
    required JwtTokenHandler tokenHandler,
    required SecureStorageService secureStorage,
    Dio? refreshDio,
  })  : _tokenHandler = tokenHandler,
        _secureStorage = secureStorage,
        _refreshDio = refreshDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  ApiConstants.headerContentType: ApiConstants.contentTypeJson,
                  ApiConstants.headerAccept: ApiConstants.contentTypeJson,
                },
              ),
            );

  final JwtTokenHandler _tokenHandler;
  final SecureStorageService _secureStorage;
  final Dio _refreshDio;

  bool _isRefreshing = false;
  Future<String?>? _refreshFuture;

  Future<String?> refreshAccessToken() async {
    if (_isRefreshing && _refreshFuture != null) {
      return _refreshFuture;
    }

    _isRefreshing = true;
    _refreshFuture = _performRefresh();

    try {
      return await _refreshFuture;
    } finally {
      _isRefreshing = false;
      _refreshFuture = null;
    }
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _tokenHandler.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const TokenRefreshException('No refresh token available');
    }

    try {
      AppLogger.i('Refreshing access token...');
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiConstants.authRefreshToken,
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      final newAccessToken = data?['access_token'] as String?;
      final newRefreshToken = data?['refresh_token'] as String? ?? refreshToken;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        throw const TokenRefreshException('Invalid refresh response');
      }

      await _tokenHandler.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      AppLogger.i('Access token refreshed successfully');
      return newAccessToken;
    } on DioException catch (e) {
      AppLogger.e('Token refresh failed', e);
      await _clearSession();
      throw TokenRefreshException(
        e.response?.data?['message'] as String? ??
            'Unable to refresh session',
      );
    } catch (e) {
      AppLogger.e('Token refresh error', e);
      await _clearSession();
      throw const TokenRefreshException();
    }
  }

  Future<void> _clearSession() async {
    await _tokenHandler.clearTokens();
    await _secureStorage.delete(StorageKeys.userId);
    await _secureStorage.delete(StorageKeys.userRole);
  }
}
