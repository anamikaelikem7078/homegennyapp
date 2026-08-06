import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import '../constants/storage_keys.dart';
import '../storage/hive_service.dart';
import '../utils/logger.dart';

/// Background FCM message handler (must be top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.i('Background message: ${message.messageId}');
}

/// Firebase Core and Cloud Messaging initialization.
class FirebaseService {
  FirebaseService({required HiveService hiveService})
      : _hiveService = hiveService;

  final HiveService _hiveService;
  FirebaseMessaging? _messaging;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _messaging = FirebaseMessaging.instance;
      _initialized = true;

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      await _requestPermission();
      await _setupToken();
      _listenToMessages();

      AppLogger.i('Firebase initialized');
    } catch (e, stack) {
      AppLogger.e('Firebase initialization skipped', e, stack);
    }
  }

  Future<void> _requestPermission() async {
    final messaging = _messaging;
    if (messaging == null) return;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _setupToken() async {
    final messaging = _messaging;
    if (messaging == null) return;

    try {
      final token = await messaging.getToken();
      if (token != null) {
        await _hiveService.saveSetting(StorageKeys.fcmToken, token);
        AppLogger.i('FCM token saved');
      }

      messaging.onTokenRefresh.listen((newToken) async {
        await _hiveService.saveSetting(StorageKeys.fcmToken, newToken);
      });
    } catch (e) {
      AppLogger.e('FCM token setup failed', e);
    }
  }

  void _listenToMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        AppLogger.i('Foreground message: ${message.notification?.title}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AppLogger.i('Message opened app: ${message.messageId}');
    });
  }

  String? get fcmToken => _hiveService.getSetting<String>(StorageKeys.fcmToken);
}
