import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:homegennyapp/app.dart';

void main() {
  testWidgets('HomeGenny app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HomeGennyApp(),
      ),
    );

    expect(find.text('HomeGenny'), findsOneWidget);
  });
}
