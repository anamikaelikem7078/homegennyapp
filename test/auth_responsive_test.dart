import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homegennyapp/common/domain/models/user_role.dart';
import 'package:homegennyapp/common/presentation/screens/biometric_login_screen.dart';
import 'package:homegennyapp/common/presentation/screens/change_password_screen.dart';
import 'package:homegennyapp/common/presentation/screens/forgot_password_screen.dart';
import 'package:homegennyapp/common/presentation/screens/login_screen.dart';
import 'package:homegennyapp/common/presentation/screens/otp_screen.dart';
import 'package:homegennyapp/common/presentation/screens/reset_password_screen.dart';
import 'package:homegennyapp/common/presentation/screens/signup_role_screen.dart';

import 'helpers/real_fonts.dart';

/// Viewports the auth flow must survive: the smallest supported phone,
/// that phone at the largest text scale the app allows (see
/// `ResponsiveFrame`), a common phone at max text, and a landscape phone.
const _viewports = <(String, Size, double)>[
  ('320x568 @1.0', Size(320, 568), 1.0),
  ('320x568 @1.3', Size(320, 568), 1.3),
  ('360x740 @1.3', Size(360, 740), 1.3),
  ('landscape 740x360', Size(740, 360), 1.0),
];

final _screens = <(String, Widget, String?)>[
  ('login', const LoginScreen(), 'Manage your sanctuary with precision.'),
  (
    'signup role',
    const SignupRoleScreen(phone: '9876543210', initialRole: UserRole.staff),
    '+91 9876543210 is new here. Tell us how you\'ll use HomeGenny.',
  ),
  ('otp', const OtpScreen(phone: '9876543210'), null),
  ('forgot password', const ForgotPasswordScreen(), null),
  ('reset password', const ResetPasswordScreen(phone: '9876543210'), null),
  ('change password', const ChangePasswordScreen(), null),
  ('biometric', const BiometricLoginScreen(), null),
];

Future<List<String>> _pump(
  WidgetTester tester,
  Widget screen,
  Size size,
  double textScale,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (d) =>
      errors.add(d.exceptionAsString().split('\n').first);
  addTearDown(() => FlutterError.onError = previous);

  await tester.pumpWidget(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    ),
  );
  // Step frame by frame: a single long pump renders one frame, before the
  // sheet's fade-in has started, so nothing in it would ever be painted.
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  FlutterError.onError = previous;
  return errors;
}

void main() {
  setUpAll(loadRealFonts);

  for (final (name, screen, heroSubtitle) in _screens) {
    for (final (label, size, scale) in _viewports) {
      testWidgets('$name lays out at $label', (tester) async {
        final errors = await _pump(tester, screen, size, scale);
        expect(errors.where((e) => e.contains('overflow')), isEmpty);

        // The hero copy must end above the sheet that slides over it.
        if (heroSubtitle != null) {
          final subtitle = find.text(heroSubtitle);
          final hero = find.ancestor(
            of: subtitle,
            matching: find.byWidgetPredicate(
              (w) => w is Stack && w.clipBehavior == Clip.hardEdge,
            ),
          );
          const sheetOverlap = 36.0;
          expect(
            tester.getRect(subtitle).bottom,
            lessThanOrEqualTo(tester.getRect(hero.first).bottom - sheetOverlap),
            reason: 'hero subtitle is hidden under the sheet',
          );
        }
      });
    }
  }
}
