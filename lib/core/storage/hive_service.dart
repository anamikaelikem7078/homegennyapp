import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import '../constants/storage_keys.dart';
import '../exceptions/app_exceptions.dart';
import '../utils/logger.dart';
import 'hive_type_registrar.dart';

/// Hive local storage initialization and access.
class HiveService {
  HiveService();

  Box<dynamic>? _settingsBox;
  Box<dynamic>? _cacheBox;
  
  // Entity Boxes
  Box<dynamic>? _staffBox;
  Box<dynamic>? _clientBox;
  Box<dynamic>? _rmBox;
  Box<dynamic>? _attendanceBox;
  Box<dynamic>? _documentBox;
  Box<dynamic>? _trainingBox;
  Box<dynamic>? _videoCertificationBox;
  Box<dynamic>? _agreementBox;
  Box<dynamic>? _placementBox;
  Box<dynamic>? _invoiceBox;
  Box<dynamic>? _paymentBox;
  Box<dynamic>? _complaintBox;
  Box<dynamic>? _replacementRequestBox;
  Box<dynamic>? _notificationBox;
  Box<dynamic>? _pendingMutationBox;

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

    registerHiveAdapters();

    _settingsBox = await Hive.openBox<dynamic>(StorageKeys.settingsBox);
    _cacheBox = await Hive.openBox<dynamic>(StorageKeys.cacheBox);
    
    _staffBox = await Hive.openBox<dynamic>('staff_box');
    _clientBox = await Hive.openBox<dynamic>('client_box');
    _rmBox = await Hive.openBox<dynamic>('rm_box');
    _attendanceBox = await Hive.openBox<dynamic>('attendance_box');
    _documentBox = await Hive.openBox<dynamic>('document_box');
    _trainingBox = await Hive.openBox<dynamic>('training_box');
    _videoCertificationBox = await Hive.openBox<dynamic>('video_certification_box');
    _agreementBox = await Hive.openBox<dynamic>('agreement_box');
    _placementBox = await Hive.openBox<dynamic>('placement_box');
    _invoiceBox = await Hive.openBox<dynamic>('invoice_box');
    _paymentBox = await Hive.openBox<dynamic>('payment_box');
    _complaintBox = await Hive.openBox<dynamic>('complaint_box');
    _replacementRequestBox = await Hive.openBox<dynamic>('replacement_request_box');
    _notificationBox = await Hive.openBox<dynamic>('notification_box');
    _pendingMutationBox = await Hive.openBox<dynamic>('pending_mutation_box');

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

  // Getters for Entity Boxes
  Box<dynamic> get staffBox => _staffBox!;
  Box<dynamic> get clientBox => _clientBox!;
  Box<dynamic> get rmBox => _rmBox!;
  Box<dynamic> get attendanceBox => _attendanceBox!;
  Box<dynamic> get documentBox => _documentBox!;
  Box<dynamic> get trainingBox => _trainingBox!;
  Box<dynamic> get videoCertificationBox => _videoCertificationBox!;
  Box<dynamic> get agreementBox => _agreementBox!;
  Box<dynamic> get placementBox => _placementBox!;
  Box<dynamic> get invoiceBox => _invoiceBox!;
  Box<dynamic> get paymentBox => _paymentBox!;
  Box<dynamic> get complaintBox => _complaintBox!;
  Box<dynamic> get replacementRequestBox => _replacementRequestBox!;
  Box<dynamic> get notificationBox => _notificationBox!;
  Box<dynamic> get pendingMutationBox => _pendingMutationBox!;


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
