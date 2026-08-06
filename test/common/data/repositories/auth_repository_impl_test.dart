import 'package:flutter_test/flutter_test.dart';
import 'package:homegennyapp/common/data/repositories/auth_repository_impl.dart';

void main() {
  group('demo auth', () {
    test('recognizes the built-in demo credentials', () {
      expect(
        AuthRepositoryImpl.isDemoCredentials(
          'demo@homegenny.com',
          'demo1234',
        ),
        isTrue,
      );

      expect(
        AuthRepositoryImpl.isDemoCredentials(
          'Demo@HomeGenny.com',
          'demo1234',
        ),
        isTrue,
      );

      expect(
        AuthRepositoryImpl.isDemoCredentials(
          'demo@homegenny.com',
          'wrong-password',
        ),
        isFalse,
      );
    });
  });
}
