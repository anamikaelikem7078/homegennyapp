import 'package:firebase_messaging/firebase_messaging.dart';

import '../constants/storage_keys.dart';
import '../firebase/firebase_service.dart';
import '../storage/hive_service.dart';

/// Push notification service wrapping Firebase Messaging.
class PushNotificationService {
  PushNotificationService({
    required FirebaseService firebaseService,
    required HiveService hiveService,
  })  : _firebase = firebaseService,
        _hive = hiveService;

  final FirebaseService _firebase;
  final HiveService _hive;

  Future<void> initialize() => _firebase.initialize();

  Future<String?> getToken() async {
    if (!_firebase.isInitialized) return _firebase.fcmToken;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _hive.saveSetting(StorageKeys.fcmToken, token);
    }
    return token ?? _firebase.fcmToken;
  }

  String? get cachedToken => _hive.getSetting<String>(StorageKeys.fcmToken) ?? _firebase.fcmToken;

  Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  void listenForeground(void Function(String title, String body) handler) {
    FirebaseMessaging.onMessage.listen((message) {
      handler(
        message.notification?.title ?? '',
        message.notification?.body ?? '',
      );
    });
  }

  void listenOpenedApp(void Function(String? route) handler) {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handler(message.data['route'] as String?);
    });
  }
}
