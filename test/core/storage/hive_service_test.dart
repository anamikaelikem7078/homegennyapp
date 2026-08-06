import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:homegennyapp/core/storage/hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HiveService hiveService;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive-test');
    Hive.init(tempDir.path);
    hiveService = HiveService();
    await hiveService.init();
    await hiveService.clearAll();
  });

  tearDown(() async {
    await hiveService.clearAll();
  });

  test('expires cached entries when their ttl elapses', () async {
    await hiveService.saveCacheWithTtl('profile', {
      'name': 'Ava',
    }, const Duration(milliseconds: 50));

    expect(hiveService.getCache<Map<String, String>>('profile'), {
      'name': 'Ava',
    });

    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(hiveService.getCache<Map<String, String>>('profile'), isNull);
  });
}
