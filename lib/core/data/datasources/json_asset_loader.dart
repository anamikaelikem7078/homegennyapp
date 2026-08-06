import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads dummy JSON assets from `assets/json/`.
class JsonAssetLoader {
  JsonAssetLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, dynamic> _memoryCache = {};

  Future<Map<String, dynamic>> loadMap(String assetPath) async {
    if (_memoryCache.containsKey(assetPath)) {
      return _memoryCache[assetPath] as Map<String, dynamic>;
    }
    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _memoryCache[assetPath] = decoded;
    return decoded;
  }

  Future<List<Map<String, dynamic>>> loadList(String assetPath) async {
    final map = await loadMap(assetPath);
    final data = map['data'] ?? map['items'] ?? map;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [map];
  }

  void clearCache() => _memoryCache.clear();
}
