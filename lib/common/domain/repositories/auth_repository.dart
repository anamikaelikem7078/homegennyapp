import '../../../../core/utils/result.dart';
import '../models/app_version_info.dart';
import '../models/auth_tokens.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

/// Authentication repository contract (domain layer).
abstract interface class AuthRepository {
  Future<Result<AuthTokens>> login({
    required String phone,
    required String password,
  });

  Future<Result<UserModel>> registerStaff({
    required String fullName,
    required String phone,
    String? alternatePhone,
    String? email,
    required String password,
    required String dateOfBirth,
    required String gender,
    required String address,
    String? city,
    String? stateName,
    String? pincode,
    required String series,
  });

  Future<Result<UserModel>> registerCustomer({
    required String fullName,
    required String phone,
    String? email,
    required String password,
    String? businessName,
    required String panCard,
    required String address,
    String? city,
    String? stateName,
    String? pincode,
    String? gstn,
  });

  Future<Result<bool>> verifyOtp({
    required String phone,
    required String otp,
  });

  Future<Result<void>> forgotPassword({required String phone});

  Future<Result<void>> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  });

  Future<Result<void>> changePassword({
    required String otp,
    required String newPassword,
  });

  Future<Result<UserModel>> getUserProfile();

  Future<Result<AppVersionInfo>> checkAppVersion();

  Future<UserRole?> getCachedUserRole();

  Future<UserModel?> getCachedUser();

  Future<bool> hasValidSession();

  Future<bool> isBiometricEnabled();

  Future<void> setBiometricEnabled(bool enabled);

  Future<void> logout();
}
