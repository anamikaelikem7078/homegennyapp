import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homegennyapp/common/domain/models/user_role.dart';
import 'package:homegennyapp/common/presentation/screens/signup_role_screen.dart';
import 'package:homegennyapp/core/onboarding/onboarding_wizard_scaffold.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('role screen lays out on a small phone', (tester) async {
    await _pump(tester, const SignupRoleScreen(phone: '9876543210', initialRole: UserRole.staff));
    expect(find.text('Continue as Staff'), findsOneWidget);
  });

  testWidgets('wizard scaffold with 4 steps lays out', (tester) async {
    await _pump(
      tester,
      OnboardingWizardScaffold(
        steps: const ['About you', 'Home', 'Contact', 'Review'],
        currentStep: 2,
        titleLine1: 'Someone we',
        titleHighlight: 'can call.',
        subtitle: 'A family member we can reach in an emergency.',
        onBack: () {},
        bottom: const SizedBox(key: Key('bottom'), height: 56, width: double.infinity),
        children: const [
          OnboardingSectionHeader(icon: Icons.person, title: 'Emergency contact', hint: 'Someone else'),
          SizedBox(height: 600),
        ],
      ),
    );
    // The hero and the sheet must actually be on screen…
    expect(find.text('Step 3 of 4').hitTestable(), findsOneWidget);
    expect(find.text('Emergency contact').hitTestable(), findsOneWidget);
    // …and the pinned bar must stay a bar, not fill the screen.
    final bar = tester.getRect(find.byKey(const Key('bottom')));
    expect(bar.top, greaterThan(600));
  });

  testWidgets('success view lays out', (tester) async {
    await _pump(
      tester,
      OnboardingSuccessView(
        title: "You're in!",
        message: 'Your RM Pooja Mishra will call you on 9876543210 to verify your documents.',
        nextSteps: const [
          (Icons.phone, 'Pooja Mishra calls you from 9800000002.'),
          (Icons.verified_user, 'Keep your Aadhaar card ready for verification.'),
          (Icons.school, 'Then training, and your first placement.'),
        ],
        primaryLabel: 'Go to home',
        onPrimary: () {},
      ),
    );
    expect(find.text('Go to home'), findsOneWidget);
  });
}
