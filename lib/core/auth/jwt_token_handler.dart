import 'package:jwt_decoder/jwt_decoder.dart';

import '../constants/storage_keys.dart';
import '../utils/logger.dart';
import '../storage/secure_storage_service.dart';

/// JWT token parsing, validation, and secure persistence.
class JwtTokenHandler {
  JwtTokenHandler(this._secureStorage);

  final SecureStorageService _secureStorage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // Sequential, not Future.wait/parallel: flutter_secure_storage's web
    // backend lazily generates one shared AES-GCM wrapping key on first
    // write and persists it to localStorage. Two concurrent first-writes
    // each generate their own key before either has persisted it, so
    // whichever write's key loses the race gets silently overwritten —
    // permanently orphaning whatever it encrypted (decrypting later with
    // the wrong key throws AES-GCM's `OperationError`). Writing one at a
    // time lets the first write establish the wrapping key before the
    // second write reuses it.
    await _secureStorage.write(StorageKeys.accessToken, accessToken);
    await _secureStorage.write(StorageKeys.refreshToken, refreshToken);
    AppLogger.i('Tokens saved securely');
  }

  Future<String?> getAccessToken() =>
      _secureStorage.read(StorageKeys.accessToken);

  Future<String?> getRefreshToken() =>
      _secureStorage.read(StorageKeys.refreshToken);

  Future<bool> hasValidAccessToken() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    if (token == 'demo-access-token') return true;
    return !isTokenExpired(token);
  }

  bool isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true;
    }
  }

  DateTime? getTokenExpiry(String token) {
    try {
      return JwtDecoder.getExpirationDate(token);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? decodeToken(String token) {
    try {
      return JwtDecoder.decode(token);
    } catch (e) {
      AppLogger.e('Failed to decode JWT', e);
      return null;
    }
  }

  String? getUserIdFromToken(String token) {
    final payload = decodeToken(token);
    return payload?['sub'] as String? ?? payload?['user_id'] as String?;
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(StorageKeys.accessToken),
      _secureStorage.delete(StorageKeys.refreshToken),
    ]);
  }

  Future<bool> shouldRefreshToken({Duration buffer = const Duration(minutes: 5)}) async {
    final token = await getAccessToken();
    if (token == null) return false;

    final expiry = getTokenExpiry(token);
    if (expiry == null) return true;

    return DateTime.now().add(buffer).isAfter(expiry);
  }
}
