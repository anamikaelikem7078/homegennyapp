import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around Flutter Secure Storage for sensitive data.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// A stored value that can't be decrypted is treated as absent rather than
  /// left to throw. On Flutter Web, the underlying WebCrypto decrypt can
  /// throw a raw `OperationError` (e.g. after the browser's storage
  /// partition/wrapping key changes between sessions) — every caller here
  /// already treats "no token" as "not logged in" and re-authenticates, so
  /// self-healing to null is strictly safer than an opaque crash.
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      if (kDebugMode) debugPrint('SecureStorageService: read($key) failed, treating as absent: $e');
      return null;
    }
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key: key);
  }
}
