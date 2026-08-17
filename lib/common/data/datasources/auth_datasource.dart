import '../../../core/constants/api_constants.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/network/api_service.dart';
import '../../../core/storage/hive_service.dart';
import '../models/auth_dto.dart';
import '../../domain/models/auth_tokens.dart';
import '../../domain/models/user_model.dart';

/// Remote auth API datasource.
class AuthRemoteDataSource extends BaseRemoteDataSource {
  AuthRemoteDataSource(super.dio);

  Future<AuthTokensDto> login({
    required String phone,
    required String password,
  }) async {
    final data = await postJson(
      ApiConstants.authLogin,
      data: {'phone': phone, 'password': password},
    );
    return AuthTokensDto.fromJson(data);
  }

  Future<bool> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final data = await postJson(
      ApiConstants.authVerifyOtp,
      data: {'phone': phone, 'otp': otp},
    );
    return data['valid'] == true;
  }

  Future<void> forgotPassword({required String phone}) async {
    await postJson(
      ApiConstants.authForgotPassword,
      data: {'phone': phone},
    );
  }

  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    await postJson(
      ApiConstants.authResetPassword,
      data: {'phone': phone, 'otp': otp, 'new_password': newPassword},
    );
  }

  Future<void> changePassword({
    required String otp,
    required String newPassword,
  }) async {
    await postJson(
      ApiConstants.authChangePassword,
      // POST /auth/change-password expects camelCase `newPassword` —
      // verified against the live controller signature, unlike
      // /auth/reset-password (snake_case `new_password`, a different
      // route). Sending snake_case here left the server reading
      // `body.newPassword` as undefined, which failed password-strength
      // validation regardless of what password was actually entered —
      // surfacing as a misleading "must be 8-72 characters..." error on
      // passwords that already satisfied every stated rule.
      data: {'otp': otp, 'newPassword': newPassword},
    );
  }

  Future<UserDto> getUserProfile() async {
    final data = await getJson(ApiConstants.userProfile);
    final userData = data['user'] as Map<String, dynamic>? ?? data;
    return UserDto.fromJson(userData);
  }

  Future<Map<String, dynamic>> checkAppVersion({
    required int versionCode,
    required String platform,
  }) async {
    return getJson(
      ApiConstants.appVersion,
      queryParameters: {'platform': platform, 'version': versionCode},
    );
  }

  Future<void> logout() async {
    await postJson(ApiConstants.authLogout);
  }
}

/// Local auth cache datasource.
class AuthLocalDataSource {
  AuthLocalDataSource(this._hive);

  final HiveService _hive;

  Future<void> cacheUser(UserDto user) async {
    await _hive.saveCache(StorageKeys.userProfile, user.toJson());
  }

  UserDto? getCachedUser() {
    final raw = _hive.getCache<Map<dynamic, dynamic>>(StorageKeys.userProfile);
    if (raw == null) return null;
    return UserDto.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> clearUser() async {
    await _hive.saveCache(StorageKeys.userProfile, null);
  }
}

/// Maps auth DTOs to domain models.
class AuthMapper {
  AuthTokens toTokens(AuthTokensDto dto) => AuthTokens(
        accessToken: dto.accessToken,
        refreshToken: dto.refreshToken,
        mustChangePassword: dto.mustChangePassword,
      );

  UserModel toUser(UserDto dto) => UserModel(
        id: dto.id,
        name: dto.name,
        email: dto.email,
        phone: dto.phone.isEmpty ? null : dto.phone,
        role: dto.role,
        avatarUrl: dto.avatarUrl,
      );
}
