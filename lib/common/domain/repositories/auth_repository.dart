import '../../../../core/utils/result.dart';
import '../models/app_version_info.dart';
import '../models/auth_tokens.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

/// Authentication repository contract (domain layer).
abstract interface class AuthRepository {
  Future<Result<AuthTokens>> login({
    required String email,
    required String password,
  });

  Future<Result<AuthTokens>> verifyOtp({
    required String phone,
    required String otp,
  });

  Future<Result<void>> forgotPassword({required String email});

  Future<Result<UserModel>> getUserProfile();

  Future<Result<AppVersionInfo>> checkAppVersion();

  Future<UserRole?> getCachedUserRole();

  Future<UserModel?> getCachedUser();

  Future<bool> hasValidSession();

  Future<bool> isBiometricEnabled();

  Future<void> setBiometricEnabled(bool enabled);

  Future<void> logout();
}
