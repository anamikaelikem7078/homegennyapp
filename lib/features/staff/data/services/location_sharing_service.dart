import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/staff_models.dart';
import '../../domain/repositories/staff_repository.dart';

/// Shares the staff member's GPS position with the family and RM while they
/// are checked in (`POST /staff/attendance/location`), one point per
/// server-given interval (default 5 min). Starts at check-in, stops at
/// check-out — location is never sent off duty.
///
/// Android keeps it alive through a location foreground service (the
/// persistent "Sharing your location while on duty" notification), so only
/// "while using the app" permission is needed. Points are queued in Hive
/// with their `recorded_at` and sent in batches of ≤ 50, so an offline
/// stretch is uploaded once the network is back.
class LocationSharingService {
  LocationSharingService({required StaffRepository repository, required HiveService hive})
      : _repository = repository,
        _hive = hive;

  final StaffRepository _repository;
  final HiveService _hive;

  static const _queueKey = 'staff_location_queue';
  static const _activeKey = 'staff_location_sharing_active';
  static const _maxBatch = 50;
  static const _defaultIntervalSec = 300;

  StreamSubscription<Position>? _subscription;
  Timer? _flushTimer;
  DateTime? _lastQueuedAt;
  bool _flushing = false;
  int _intervalSec = _defaultIntervalSec;

  bool get isRunning => _subscription != null;

  /// Starts sharing; returns false when location permission isn't granted
  /// (check-in still works — the family just can't see the staff member).
  Future<bool> start({int? intervalSec}) async {
    if (intervalSec != null && intervalSec > 0) _intervalSec = intervalSec;
    if (isRunning) return true;
    if (!await hasPermission()) return false;

    await _hive.saveSetting(_activeKey, true);
    _subscription = Geolocator.getPositionStream(locationSettings: _settings()).listen(
      _onPosition,
      onError: (Object e) => debugPrint('Location sharing stream error: $e'),
    );
    // Retries the queue when no new fix comes in (e.g. after going offline).
    _flushTimer = Timer.periodic(Duration(seconds: _intervalSec), (_) => flush());
    return true;
  }

  /// Stops sharing and drops any points not yet sent.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _lastQueuedAt = null;
    await _hive.saveSetting(_activeKey, false);
    await _hive.deleteSetting(_queueKey);
  }

  /// Releases the stream without touching the queue or the active flag.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  /// Resumes sharing after an app restart if the server still shows an
  /// open shift; stops it if the shift was closed elsewhere.
  Future<void> resumeIfCheckedIn() async {
    final result = await _repository.getPlacementsToday();
    await result.fold(
      onSuccess: (today) async {
        if (today.isCheckedIn) {
          await start(intervalSec: today.locationIntervalSec);
        } else if (_hive.getSetting<bool>(_activeKey) ?? false) {
          await stop();
        }
      },
      onError: (_) async {
        // Offline at launch: trust the last known state.
        if (_hive.getSetting<bool>(_activeKey) ?? false) await start();
      },
    );
  }

  static Future<bool> hasPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  LocationSettings _settings() {
    // Web (even under phone emulation) takes plain settings.
    if (kIsWeb) return const LocationSettings(accuracy: LocationAccuracy.high);
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        intervalDuration: Duration(seconds: _intervalSec),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'HomeGenny',
          notificationText: 'Sharing your location while on duty',
          setOngoing: true,
          enableWakeLock: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS has no fixed interval; _onPosition throttles to one point per
      // interval.
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high);
  }

  Future<void> _onPosition(Position position) async {
    if (position.isMocked) return;
    final now = DateTime.now();
    final last = _lastQueuedAt;
    // A little slack so a fix that arrives a few seconds early still counts.
    if (last != null && now.difference(last).inSeconds < _intervalSec - 15) return;
    _lastQueuedAt = now;

    final queue = _readQueue()
      ..add(LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy > 0 ? position.accuracy : null,
        recordedAt: position.timestamp,
      ));
    await _writeQueue(queue);
    await flush();
  }

  /// Sends queued points in batches; keeps them on network errors.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      while (true) {
        final queue = _readQueue();
        if (queue.isEmpty) return;
        final batch = queue.take(_maxBatch).toList();
        final result = await _repository.sendLocationPoints(batch);
        final keepGoing = await result.fold(
          onSuccess: (r) async {
            await _writeQueue(_readQueue().skip(batch.length).toList());
            final next = r.nextInSec;
            if (next != null && next > 0 && next != _intervalSec) await _restartWithInterval(next);
            return true;
          },
          onError: (failure) async {
            // 400 "You are not checked in": the shift is closed.
            if (failure.message.toLowerCase().contains('not checked in')) {
              await stop();
            }
            return false;
          },
        );
        if (!keepGoing) return;
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _restartWithInterval(int seconds) async {
    _intervalSec = seconds;
    if (!isRunning) return;
    await _subscription?.cancel();
    _subscription = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    await start();
  }

  List<LocationPoint> _readQueue() {
    final raw = _hive.getSetting<List<dynamic>>(_queueKey) ?? const [];
    return [
      for (final item in raw)
        if (item is Map) ?LocationPoint.fromJson(item),
    ];
  }

  Future<void> _writeQueue(List<LocationPoint> points) =>
      _hive.saveSetting(_queueKey, [for (final p in points) p.toJson()]);
}

final locationSharingServiceProvider = Provider<LocationSharingService>((ref) {
  final service = LocationSharingService(
    repository: ref.watch(staffRepositoryProvider),
    hive: ref.watch(hiveServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
