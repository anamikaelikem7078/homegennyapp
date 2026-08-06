import '../../storage/hive_service.dart';

/// Base Hive cache operations for feature local datasources.
abstract class BaseLocalDataSource {
  BaseLocalDataSource(this._hive);

  final HiveService _hive;

  Future<void> saveJson(String key, Map<String, dynamic> json) async {
    await _hive.saveCache(key, json);
  }

  Future<void> saveJsonList(String key, List<Map<String, dynamic>> json) async {
    await _hive.saveCache(key, json);
  }

  Map<String, dynamic>? getJson(String key) {
    final raw = _hive.getCache<dynamic>(key);
    if (raw == null) return null;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  List<Map<String, dynamic>>? getJsonList(String key) {
    final raw = _hive.getCache<dynamic>(key);
    if (raw == null) return null;
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  Future<void> delete(String key) async {
    await _hive.saveCache(key, null);
  }
}
