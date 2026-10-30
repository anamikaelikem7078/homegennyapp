// Walks the real app the way a user would and saves a screenshot of every
// step for the plain-language user guides in docs/user_guides/.
//
//   flutter test test/user_flow_walkthrough_test.dart \
//     --dart-define=USE_DUMMY_API=true --dart-define=ENABLE_OFFLINE_CACHE=false
//
// Each journey logs in through the real login + OTP screens with the built-in
// demo numbers, then taps visible buttons by their label. A step that can't
// be reached by tapping is printed as a `FLOW|MISS|` line (and reached by its
// route instead) so it can be reported rather than hidden. Every screen's
// visible text is printed as `FLOW|TEXT|` lines.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as gf;
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:homegennyapp/app.dart';
import 'package:homegennyapp/core/data/seed_data_service.dart';
import 'package:homegennyapp/core/di/injection.dart';
import 'package:homegennyapp/core/network/dio_client.dart';
import 'package:homegennyapp/core/network/network_info.dart';
import 'package:homegennyapp/core/router/app_router.dart';
import 'package:homegennyapp/core/storage/hive_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fixtures/fake_backend_fixtures.dart';

const _outDir = 'docs/user_guides/screenshots';
const _fontDir = 'test/fixtures/google_fonts';

/// Plus Jakarta Sans files google_fonts asks for, by weight.
const _jakarta = {
  '200': '18957f66e783faa14c9aa99f338d8184a801b007b9a42e4483200d34a8aa89d1',
  '300': 'b174b658c98eea68d1c3ce9711ee58b229eafcffa43d3e9d18f39bc8b9ca0526',
  'regular': '80501e2c94323d8b8d48b29bc73aa042539f0a6e62c3afe318980de7b7b19267',
  '500': 'd69a8aa421db9df3e7d624119c9ee103d342e1dacff8bb29e36eebd379fdb7de',
  '600': 'ba0432c50b99a58d041dc19291e1ff0a3c0e17fa254fe58510a96248426718d6',
  '700': 'dbf8d18a2d1c11f9b68005f52aaefe3974273175b1048047d662a13858c1e9e6',
  '800': '16b18d8f75d223acf2959d157e76addcbf64e153a7262b05aefc2f4c6f47ebca',
};

/// The app's real fonts, so screenshots look like the phone: google_fonts
/// is served the files in [_fontDir] (downloaded from fonts.gstatic.com)
/// instead of fetching them, and Plus Jakarta Sans is registered up front so
/// the first frame isn't drawn with a fallback.
Future<void> _loadAppFonts() async {
  gf.httpClient = MockClient((req) async {
    final f = File('$_fontDir/${req.url.pathSegments.last}');
    return f.existsSync()
        ? http.Response.bytes(f.readAsBytesSync(), 200)
        : http.Response('', 404);
  });
  Future<void> load(String family, String path) async {
    final bytes = await File(path).readAsBytes();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }

  for (final MapEntry(key: weight, value: hash) in _jakarta.entries) {
    await load('PlusJakartaSans_$weight', '$_fontDir/$hash.ttf');
  }
  // flutter_tester lives in <sdk>/bin/cache/artifacts/engine/<platform>/.
  final sdkFonts =
      '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
  await load('Roboto', '$sdkFonts/roboto-regular.ttf');
  await load('MaterialIcons', '$sdkFonts/materialicons-regular.otf');
}

/// Stands in for https://homegenny.com/api/v1 for endpoints the dummy data
/// sources don't cover (staff requests, care, RM…). Answers come from
/// [fakeBackendFixtures]; anything else is a 404, printed as `FLOW|API|` so the gap
/// is visible.
class _FakeBackend implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path.replaceFirst(RegExp(r'^/api/v1'), '');
    final key = '${options.method} $path';
    for (final MapEntry(key: pattern, value: body)
        in fakeBackendFixtures.entries) {
      if (RegExp('^$pattern\$').hasMatch(key)) {
        Object? data;
        try {
          data = switch (body) {
            Object? Function() f => f(),
            Object? Function(RequestOptions) f => f(options),
            _ => body,
          };
        } catch (e) {
          // A fixture can answer with an HTTP error (e.g. wrong password).
          final (status, errorBody) = fakeBackendError(e) ?? (500, {});
          // ignore: avoid_print
          print('FLOW|API|$status|$key');
          return ResponseBody.fromString(
            jsonEncode(errorBody),
            status,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        // ignore: avoid_print
        print('FLOW|API|200|$key');
        return ResponseBody.fromString(
          jsonEncode(data),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
    }
    // ignore: avoid_print
    print('FLOW|API|404|$key');
    return ResponseBody.fromString(
      '{"message":"not in fake backend"}',
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _OnlineNetworkInfo extends NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(true);
}

/// Drives one running copy of the app.
class _Walker {
  _Walker(this.tester, this.container, this.folder);

  final WidgetTester tester;
  final ProviderContainer container;
  final String folder;
  final _boundary = GlobalKey();
  int _n = 0;

  GoRouter get router => container.read(routerProvider);

  /// The screen on top, including ones opened with `push`.
  String get location {
    final config = router.routerDelegate.currentConfiguration;
    return config.isEmpty ? config.uri.toString() : config.last.matchedLocation;
  }

  Widget app(Widget child) => RepaintBoundary(key: _boundary, child: child);

  /// Frame by frame: long enough for the dummy API delay and entrance
  /// animations, without waiting on looping shimmer animations.
  /// Real time is let through between frames so Hive / file IO (which the
  /// test's fake clock can't advance) completes.
  Future<void> settle([int frames = 20]) async {
    for (var i = 0; i < frames; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Saves the current screen as `NN_name.png` and prints its text.
  Future<void> shot(String name) async {
    await settle(4);
    _n++;
    final file = File(
      '$_outDir/$folder/${_n.toString().padLeft(2, '0')}_$name.png',
    );
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    // ignore: avoid_print
    print('FLOW|SHOT|$folder|${file.path}|$location');
    final texts = <String>[];
    for (final t in tester.widgetList<RichText>(find.byType(RichText))) {
      final s = t.text.toPlainText().trim().replaceAll('\n', ' ');
      if (s.isNotEmpty && s.runes.first < 0xE000) texts.add(s);
    }
    // ignore: avoid_print
    print('FLOW|TEXT|$folder|${_n}_$name|${texts.join(' ¦ ')}');
  }

  void miss(String what) {
    // ignore: avoid_print
    print('FLOW|MISS|$folder|$what|at $location');
  }

  /// Taps the first visible widget showing [label]. Returns false (and logs
  /// a miss) when nothing on screen shows it.
  Future<bool> tap(String label, {bool scroll = true, int frames = 20}) async {
    var f = find.text(label, findRichText: true);
    if (f.evaluate().isEmpty) {
      f = find.textContaining(label, findRichText: true);
    }
    if (f.evaluate().isEmpty && scroll) {
      // Not on screen yet: scroll the page down (the first vertical list
      // is the page itself), up to a few screens.
      final page = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      for (var i = 0; i < 12 && f.evaluate().isEmpty; i++) {
        if (page.evaluate().isEmpty) break;
        await tester.drag(
          page.first,
          const Offset(0, -300),
          warnIfMissed: false,
        );
        await settle(3);
        f = find.textContaining(label, findRichText: true);
      }
    }
    if (f.evaluate().isEmpty) {
      miss('no "$label" to tap');
      return false;
    }
    await tester.ensureVisible(f.first);
    await tester.pump();
    await tester.tap(f.first, warnIfMissed: false);
    await settle(frames);
    return true;
  }

  /// Taps [label]; if it isn't there, opens [route] directly so the walk
  /// can go on.
  Future<void> tapOr(String label, String route) async {
    if (!await tap(label)) await goTo(route);
  }

  Future<void> goTo(String route) async {
    router.go(route);
    await settle();
  }

  Future<void> push(String route) async {
    router.push(route);
    await settle();
  }

  Future<void> back() async {
    if (router.canPop()) router.pop();
    await settle(8);
  }

  Future<void> scrollDown([double by = 500]) async {
    final s = find.byType(Scrollable);
    if (s.evaluate().isEmpty) return;
    await tester.drag(s.first, Offset(0, -by), warnIfMissed: false);
    await settle(6);
  }

  Future<void> enterFirstField(String text) async {
    await tester.enterText(find.byType(EditableText).first, text);
    await settle(6);
  }
}

/// Boots the whole app (splash → login → OTP) logged in as [phone], or
/// stopped on the login screen without one.
Future<_Walker> _start(
  WidgetTester tester,
  HiveService hive,
  String folder, {
  String? phone,
  bool shootSplash = false,
}) async {
  // Errors from things that don't exist in tests (camera, web photos…) are
  // not flow problems; print them and carry on.
  _previousOnError = FlutterError.onError;
  FlutterError.onError = (d) {
    // ignore: avoid_print
    print('FLOW|ERR|${d.exceptionAsString().split('\n').first}');
  };
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  FlutterSecureStorage.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'HomeGenny',
    packageName: 'com.homegenny.app',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );

  final container = ProviderContainer(
    overrides: [
      hiveServiceProvider.overrideWithValue(hive),
      networkInfoProvider.overrideWithValue(_OnlineNetworkInfo()),
      dioClientProvider.overrideWith(
        (ref) => DioClient(
          authInterceptor: ref.watch(authInterceptorProvider),
          dio: Dio()..httpClientAdapter = _FakeBackend(),
        ),
      ),
    ],
  );
  final w = _Walker(tester, container, folder);

  await tester.pumpWidget(
    w.app(
      UncontrolledProviderScope(
        container: container,
        child: const HomeGennyApp(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  if (shootSplash) await w.shot('splash');
  await w.settle(40);
  // No phone: stop on the login screen.
  if (phone == null) return w;

  await tester.enterText(find.byType(EditableText).first, phone);
  await w.settle(4);
  await w.tap('Continue');
  await tester.enterText(find.byType(EditableText).first, '123456');
  // Typing the 6th digit verifies by itself; wait for the home to open.
  for (
    var i = 0;
    i < 150 && const ['/', '/login', '/otp'].contains(w.location);
    i++
  ) {
    // Saving the login to local storage takes real time.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await w.settle(1);
  }
  await w.settle(20);
  return w;
}

void Function(FlutterErrorDetails)? _previousOnError;

Future<void> _finish(_Walker w) async {
  await w.tester.pumpWidget(const SizedBox());
  w.container.dispose();
  await w.tester.pump(const Duration(seconds: 5));
  FlutterError.onError = _previousOnError;
}

void main() {
  final hive = HiveService();
  setUpAll(() async {
    await _loadAppFonts();
    // google_fonts caches downloaded files in the app support directory.
    final support = Directory.systemTemp.createTempSync('hg_support').path;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => support,
    );
    // Google Maps is a platform view and the voice-note recorder a plugin;
    // neither exists in tests. The map area renders empty.
    messenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      (call) async => call.method == 'create' ? 0 : null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (call) async => null,
    );
    for (var i = 0; i < 20; i++) {
      messenger.setMockMethodCallHandler(
        MethodChannel('plugins.flutter.io/google_maps_$i'),
        (call) async => null,
      );
    }
    // GPS: location on, permission given, the phone standing at the
    // client's home in Green Park (where the demo placement is).
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (call) async => switch (call.method) {
        'isLocationServiceEnabled' => true,
        'checkPermission' || 'requestPermission' => 3, // always
        'getCurrentPosition' || 'getLastKnownPosition' => {
          'latitude': 28.5593,
          'longitude': 77.2067,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'accuracy': 8.0,
          'altitude': 216.0,
          'altitude_accuracy': 3.0,
          'heading': 0.0,
          'heading_accuracy': 0.0,
          'speed': 0.0,
          'speed_accuracy': 0.0,
          'is_mocked': false,
        },
        _ => null,
      },
    );
    await hive.init();
    await SeedDataService(hive).seedIfEmpty();
  });

  // ── Client ──
  testWidgets('client', (tester) async {
    final w = await _start(tester, hive, 'client', phone: '9800000004');
    await w.shot('home');
    await w.scrollDown(600);
    await w.shot('home_quick_actions');

    // Ask for staff.
    await w.tapOr('Request staff', '/client/staff-requests/new');
    await w.shot('request_step1_kind');
    await w.tap('Regular staff');
    await w.tap('Unskilled Caretaker');
    await w.shot('request_step1_filled');
    await w.tap('Next');
    await w.tap('Tmrw');
    await w.tap('9:00 AM');
    await w.scrollTop();
    await w.shot('request_step2_when');
    await w.tap('Next');
    await w.fill("Patient's age", '78');
    await w.tap('Assisted');
    await w.scrollTop();
    await w.shot('request_step3_needs');
    await w.tap('Next');
    await w.fill('Address', '42, Green Park Extension, New Delhi - 110016');
    await w.shot('request_step4_address');
    await w.tap('Next');
    await w.shot('request_step5_review');
    await w.tap('Send request', frames: 30);
    await w.shot('request_sent');

    // Follow the request and choose staff.
    await w.goTo('/client/dashboard');
    await w.tapOr('My requests', '/client/staff-requests');
    await w.shot('my_requests');
    await w.tapOr('REQ-2026-0142', '/client/staff-requests/req-1');
    await w.shot('request_ready_to_choose');
    await w.scrollDown(500);
    await w.shot('request_candidates');
    await w.tap('Choose');
    await w.shot('choose_confirm');
    await w.dismiss();
    await w.tap('None of these');
    await w.shot('none_of_these');
    await w.dismiss();

    // Staff at home: the card's name opens the profile, its progress line
    // opens the meals (cook) or the day's care (caretaker).
    await w.goTo('/client/dashboard');
    await w.tapOr('Rajesh · Cook', '/client/staff/staff001');
    await w.shot('staff_profile_from_home');
    await w.goTo('/client/dashboard');
    await w.tapOr('1/3 meals', '/client/care/PLC-001/meals');
    await w.shot('cook_meals');
    await w.tap('Rate');
    await w.shot('rate_meal');
    await w.dismiss();
    await w.goTo('/client/dashboard');
    await w.tapOr('2/4 tasks', '/client/care/PLC-002');
    await w.shot('care_today');
    await w.goTo('/client/staff');
    await w.shot('staff_tab');
    await w.scrollDown(600);
    await w.shot('staff_tab_more');
    await w.goTo('/client/care/PLC-001/menu');
    await w.shot('week_menu');
    await w.goTo('/client/food-profile');
    await w.shot('food_profile');
    await w.goTo('/client/care/PLC-002/plan');
    await w.shot('care_plan');
    await w.goTo('/client/care/PLC-002/instructions');
    await w.shot('instructions');
    await w.tapOr('New instruction', '/client/care/PLC-002/instructions/new');
    await w.shot('new_instruction');
    await w.goTo('/client/staff/staff001');
    await w.shot('staff_profile');

    // Attendance.
    await w.goTo('/client/dashboard');
    await w.tapOr('Attendance', '/client/attendance-summary');
    await w.shot('attendance_summary');
    await w.tapOr("Today's Attendance", '/client/attendance/today');
    await w.shot('attendance_today');
    await w.tapOr('Raise an issue', '/client/attendance/raise-issue');
    await w.shot('attendance_raise_issue');
    await w.goTo('/client/attendance/history');
    await w.shot('attendance_history');

    // Pay.
    await w.goTo('/client/payments');
    await w.shot('pay_tab');
    await w.tapOr('Pay Now', '/client/payments/invoice');
    await w.shot('invoice');
    await w.tapOr('Proceed to Payment', '/client/payments/gateway');
    await w.shot('pay_upi');
    await w.goTo('/client/payments/history');
    await w.shot('payment_history');

    // Problems.
    await w.goTo('/client/dashboard');
    await w.tapOr('Complaint', '/client/complaint/raise');
    await w.shot('complaint');
    await w.goTo('/client/complaint/history');
    await w.shot('complaint_history');
    await w.goTo('/client/dashboard');
    await w.tapOr('Replace', '/client/replacement/request');
    await w.shot('replacement');

    // Notifications and settings.
    await w.goTo('/client/notifications');
    await w.shot('notifications');
    await w.goTo('/client/settings');
    await w.shot('settings');
    await w.goTo('/client/profile');
    await w.shot('profile');
    await _finish(w);
  });

  // ── Staff ──
  testWidgets('staff', (tester) async {
    final w = await _start(tester, hive, 'staff', phone: '9800000002');
    await w.shot('home');
    await w.scrollDown(600);
    await w.shot('home_more');

    // Getting vetted.
    await w.goTo('/staff/pipeline');
    await w.shot('pipeline');
    await w.scrollDown(600);
    await w.shot('pipeline_more');
    await w.goTo('/staff/complete-profile');
    await w.shot('profile_wizard');
    await w.goTo('/staff/profile/completion');
    await w.shot('profile_completion');
    await w.goTo('/staff/documents');
    await w.shot('documents');
    await w.goTo('/staff/documents/upload');
    await w.shot('document_upload');
    await w.goTo('/staff/training');
    await w.shot('training');
    if (await w.tap('Start')) await w.shot('quiz');
    await w.goTo('/staff/video-certification');
    await w.shot('video_certification');
    await w.goTo('/staff/agreement');
    await w.shot('agreement');
    await w.goTo('/staff/agreement/signature');
    await w.shot('agreement_sign');
    await w.goTo('/staff/agreement/status');
    await w.shot('agreement_status');
    await w.goTo('/staff/deployment');
    await w.shot('deployment');

    // Daily work.
    await w.goTo('/staff/home');
    await w.tapOr('Check in', '/staff/attendance/check-in');
    await w.shot('check_in_location_consent');
    await w.tap('I understand');
    await w.shot('check_in');
    await w.scrollDown(600);
    await w.shot('check_in_more');
    await w.goTo('/staff/attendance');
    await w.shot('attendance_tab');
    await w.goTo('/staff/attendance/history');
    await w.shot('attendance_history');
    await w.goTo('/staff/attendance/monthly');
    await w.shot('attendance_monthly');
    await w.goTo('/staff/care/today');
    await w.shot('care_today');
    await w.goTo('/staff/care/PLC-002/report');
    await w.shot('care_daily_report');
    await w.goTo('/staff/instructions');
    await w.shot('instructions');
    await w.goTo('/staff/client-updates');
    await w.shot('client_updates');
    await w.goTo('/staff/cook/today');
    await w.shot('cook_today');
    await w.goTo('/staff/cook/PLC-001/ratings');
    await w.shot('cook_ratings');

    // Pay.
    await w.goTo('/staff/salary');
    await w.shot('salary');
    await w.tapOr('Payslip history', '/staff/salary/history');
    await w.shot('salary_history');
    await w.goTo('/staff/salary/bank');
    await w.shot('bank');
    await w.goTo('/staff/profile');
    await w.shot('profile');
    await _finish(w);
  });

  // ── RM ──
  testWidgets('rm', (tester) async {
    final w = await _start(tester, hive, 'rm', phone: '9800000001');
    await w.shot('dashboard');
    await w.scrollDown(600);
    await w.shot('dashboard_more');
    await w.goTo('/rm/requests');
    await w.shot('signup_requests');
    await w.tap('Accept');
    await w.shot('signup_accept');
    await w.dismiss();

    await w.goTo('/rm/pipeline');
    await w.shot('pipeline');
    await w.tapOr('Sunita Devi', '/rm/staff/stf-101');
    await w.shot('staff_detail');
    await w.scrollDown(600);
    await w.shot('staff_detail_more');
    await w.goTo('/rm/staff/stf-203/verification');
    await w.shot('verification');
    await w.goTo('/rm/staff/stf-203/verification/track1');
    await w.shot('verification_aadhaar');
    await w.goTo('/rm/staff/stf-203/verification/track4');
    await w.shot('verification_police');
    await w.goTo('/rm/staff/stf-205/stage3/video-review');
    await w.shot('video_review');
    await w.goTo('/rm/staff/stf-206/stage4/hub');
    await w.shot('agreements');
    await w.goTo('/rm/staff/stf-101/stage5/hub');
    await w.shot('deploy');
    await w.goTo('/rm/staff/stf-101/placement/create');
    await w.shot('placement_create');
    await w.scrollDown(700);
    await w.shot('placement_create_more');

    await w.goTo('/rm/trials');
    await w.shot('trials');
    await w.tapOr('Sunita Devi', '/rm/placements/plc-1');
    await w.shot('placement_detail');

    await w.goTo('/rm/tasks');
    await w.shot('shifts');
    await w.goTo('/rm/alerts');
    await w.shot('incidents');
    await w.goTo('/rm/attendance');
    await w.shot('attendance');
    await w.tapOr('Invoice', '/rm/staff/stf-101/invoice-preview');
    await w.shot('invoice_preview');
    await w.scrollDown(700);
    await w.shot('invoice_preview_more');
    await w.goTo('/rm/deferred');
    await w.shot('deferred');
    await w.goTo('/rm/upgrades');
    await w.shot('upgrades');
    await _finish(w);
  });
  // ── Everyone: open the app and log in ──
  testWidgets('common', (tester) async {
    final w = await _start(tester, hive, 'common', shootSplash: true);
    await w.shot('login');
    await tester.enterText(find.byType(EditableText).first, '9800000004');
    await w.settle(4);
    await w.shot('login_number_entered');
    await w.tap('Continue');
    await w.shot('otp');
    await tester.enterText(find.byType(EditableText).first, '123456');
    for (
      var i = 0;
      i < 100 && const ['/', '/login', '/otp'].contains(w.location);
      i++
    ) {
      await w.settle(1);
    }
    await w.settle(20);
    await w.shot('home_after_login');
    await _finish(w);
  });

  // ── An office (RM) account: the server says it signs in with a password ──
  testWidgets('office login', (tester) async {
    final w = await _start(tester, hive, 'office');
    await tester.enterText(find.byType(EditableText).first, '9811100001');
    await w.settle(4);
    await w.tap('Continue');
    await w.shot('password_sheet');
    await tester.enterText(find.byType(EditableText).last, 'wrong-password');
    await w.settle(2);
    await w.tap('Log in');
    await w.shot('wrong_password');
    await tester.enterText(find.byType(EditableText).last, 'Office@123');
    await w.settle(2);
    await w.tap('Log in');
    for (var i = 0; i < 100 && !w.location.startsWith('/rm'); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await w.settle(1);
    }
    await w.settle(10);
    await w.shot('rm_dashboard');
    expect(w.location, startsWith('/rm'));
    await _finish(w);
  });

  // ── A new number signs up ──
  testWidgets('signup', (tester) async {
    final w = await _start(tester, hive, 'signup');
    await tester.enterText(find.byType(EditableText).first, '9812345678');
    await w.settle(4);
    await w.tap('Continue');
    await w.shot('new_number_pick_role');
    await w.tap('I need help at home');
    await w.shot('role_client_selected');
    await w.tap('Continue as Client');
    await w.shot('otp_new_client');
    await w.typeCode('123456');
    for (var i = 0; i < 100 && !w.location.startsWith('/client'); i++) {
      await w.settle(1);
    }
    await w.settle(10);
    // The live server opens the profile wizard here; dummy mode skips it.
    await w.goTo('/client/complete-profile');
    await w.shot('client_profile_wizard_step1');
    await w.fill('Your name', 'Neha Kapoor');
    await w.tapOr('Next', '/client/complete-profile?step=1');
    await w.shot('client_profile_wizard_step2');
    await _finish(w);
  });
}

extension on _Walker {
  /// Types into the labelled form field showing [label].
  Future<void> fill(String label, String text) async {
    final field = find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == 'DsLabeledField',
      ),
    );
    final input = field.evaluate().isNotEmpty
        ? find.descendant(of: field.first, matching: find.byType(EditableText))
        : find.byType(EditableText);
    if (input.evaluate().isEmpty) {
      miss('no field "$label"');
      return;
    }
    await tester.ensureVisible(input.first);
    await tester.enterText(input.first, text);
    await settle(4);
  }

  /// Scrolls the page back to the top.
  Future<void> scrollTop() async {
    final page = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    if (page.evaluate().isEmpty) return;
    for (var i = 0; i < 6; i++) {
      await tester.drag(page.first, const Offset(0, 600), warnIfMissed: false);
      await settle(2);
    }
    await settle(4);
  }

  /// Closes a dialog or sheet by tapping outside it.
  Future<void> dismiss() async {
    await tester.tapAt(const Offset(195, 40));
    await settle(8);
  }
}

extension on _Walker {
  /// Types into the first text box on screen, if there is one.
  Future<void> typeCode(String text) async {
    final input = find.byType(EditableText);
    if (input.evaluate().isEmpty) {
      miss('no text box for "$text"');
      return;
    }
    await tester.enterText(input.first, text);
    await settle(4);
  }
}
