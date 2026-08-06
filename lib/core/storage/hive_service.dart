import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import '../constants/storage_keys.dart';
import '../exceptions/app_exceptions.dart';
import '../utils/logger.dart';

/// Hive local storage initialization and access.
class HiveService {
  HiveService();

  Box<dynamic>? _settingsBox;
  Box<dynamic>? _cacheBox;

  bool get isInitialized => _settingsBox != null && _cacheBox != null;

  Future<void> init() async {
    if (isInitialized) return;

    try {
      await Hive.initFlutter();
    } catch (error) {
      final fallbackDir = await Directory.systemTemp.createTemp(
        'homegenny_hive',
      );
      Hive.init(fallbackDir.path);
    }

    _settingsBox = await Hive.openBox<dynamic>(StorageKeys.settingsBox);
    _cacheBox = await Hive.openBox<dynamic>(StorageKeys.cacheBox);
    AppLogger.i('Hive initialized');
  }

  Box<dynamic> get settingsBox {
    final box = _settingsBox;
    if (box == null) {
      throw const CacheException('Hive settings box not initialized');
    }
    return box;
  }

  Box<dynamic> get cacheBox {
    final box = _cacheBox;
    if (box == null) {
      throw const CacheException('Hive cache box not initialized');
    }
    return box;
  }

  Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  T? getSetting<T>(String key) {
    return settingsBox.get(key) as T?;
  }

  Future<void> deleteSetting(String key) async {
    await settingsBox.delete(key);
  }

  Future<void> saveCache(String key, dynamic value) async {
    await cacheBox.put(key, value);
  }

  Future<void> saveCacheWithTtl(String key, dynamic value, Duration ttl) async {
    final expiresAt = DateTime.now().add(ttl).millisecondsSinceEpoch;
    await cacheBox.put(key, {'value': value, 'expiresAt': expiresAt});
  }

  T? getCache<T>(String key) {
    final raw = cacheBox.get(key);
    if (raw is Map && raw['value'] != null && raw['expiresAt'] != null) {
      final expiresAt = raw['expiresAt'] as int?;
      if (expiresAt != null &&
          expiresAt <= DateTime.now().millisecondsSinceEpoch) {
        cacheBox.delete(key);
        return null;
      }
      return raw['value'] as T?;
    }
    return raw as T?;
  }

  Future<void> clearCache() async {
    await cacheBox.clear();
  }

  Future<void> clearAll() async {
    await settingsBox.clear();
    await cacheBox.clear();
  }
}
