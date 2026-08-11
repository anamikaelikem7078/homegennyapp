import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/auth/jwt_token_handler.dart';
import '../../../core/data/repository_executor.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/exceptions/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/utils/result.dart';
import '../../domain/models/app_version_info.dart';
import '../../domain/models/auth_tokens.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';
import '../models/auth_dto.dart';

/// Authentication repository — remote + local cache.
class AuthRepositoryImpl implements AuthRepository {
  static const _demoPassword = 'demo1234';

  static const _demoClientPhone = '+15550000001';
  static const _demoStaffPhone = '+15550000002';
  static const _demoRmPhone = '+15550000003';

  static const _demoClientName = 'Demo Client';
  static const _demoStaffName = 'Demo Staff';
  static const _demoRmName = 'Demo RM';

  AuthRepositoryImpl({
    required DioClient dioClient,
    required JwtTokenHandler tokenHandler,
    required SecureStorageService secureStorage,
    required HiveService hiveService,
    AuthRemoteDataSource? remote,
    AuthLocalDataSource? local,
    AuthMapper? mapper,
  })  : _tokenHandler = tokenHandler,
        _secureStorage = secureStorage,
        _remote = remote ?? AuthRemoteDataSource(dioClient),
        _local = local ?? AuthLocalDataSource(hiveService),
        _mapper = mapper ?? AuthMapper();

  final JwtTokenHandler _tokenHandler;
  final SecureStorageService _secureStorage;
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final AuthMapper _mapper;

  static bool isDemoCredentials(String phone, String password) {
    final lowerPhone = phone.trim().toLowerCase();
    return (lowerPhone == _demoClientPhone ||
            lowerPhone == _demoStaffPhone ||
            lowerPhone == _demoRmPhone) &&
        password.trim() == _demoPassword;
  }

  @override
  Future<Result<AuthTokens>> login({
    required String phone,
    required String password,
  }) async {
    if (isDemoCredentials(phone, password)) {
      await _tokenHandler.saveTokens(
        accessToken: 'demo-access-token',
        refreshToken: 'demo-refresh-token',
      );
      await _secureStorage.write(StorageKeys.lastLoginEmail, phone);
      return const Success(AuthTokens(
        accessToken: 'demo-access-token',
        refreshToken: 'demo-refresh-token',
      ));
    }

    try {
      final dto = await _remote.login(phone: phone, password: password);
      final tokens = _mapper.toTokens(dto);
      await _tokenHandler.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      await _secureStorage.write(StorageKeys.lastLoginEmail, phone);
      return Success(tokens);
    } catch (e, stack) {
      return Error(ExceptionHandler.handle(e, stack));
    }
  }

  @override
  Future<Result<AuthTokens>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final lowerPhone = phone.trim().toLowerCase();
    if (lowerPhone == _demoClientPhone ||
        lowerPhone == _demoStaffPhone ||
        lowerPhone == _demoRmPhone) {
      if (otp != '1234') {
        return const Error(AuthFailure(message: 'Invalid demo OTP. Use 1234.'));
      }
      return const Success(AuthTokens(
        accessToken: 'demo-access-token',
        refreshToken: 'demo-refresh-token',
      ));
    }

    try {
      final dto = await _remote.verifyOtp(phone: phone, otp: otp);
      final tokens = _mapper.toTokens(dto);
      await _tokenHandler.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return Success(tokens);
    } catch (e, stack) {
      return Error(ExceptionHandler.handle(e, stack));
    }
  }

  @override
  Future<Result<void>> forgotPassword({required String email}) async {
    try {
      await _remote.forgotPassword(email: email);
      return const Success(null);
    } catch (e, stack) {
      return Error(ExceptionHandler.handle(e, stack));
    }
  }

  @override
  Future<Result<UserModel>> getUserProfile() async {
    final savedPhone = await _secureStorage.read(StorageKeys.lastLoginEmail);
    final lowerPhone = savedPhone?.trim().toLowerCase();
    
    if (lowerPhone == _demoClientPhone || lowerPhone == _demoStaffPhone || lowerPhone == _demoRmPhone) {
      late String demoName;
      late UserRole demoRole;

      if (lowerPhone == _demoStaffPhone) {
        demoName = _demoStaffName;
        demoRole = UserRole.staff;
      } else if (lowerPhone == _demoRmPhone) {
        demoName = _demoRmName;
        demoRole = UserRole.rm;
      } else {
        demoName = _demoClientName;
        demoRole = UserRole.client;
      }

      final demoUser = UserModel(
        id: 'demo-user-${demoRole.value}',
        name: demoName,
        email: 'demo@homegenny.com',
        role: demoRole,
      );
      await _secureStorage.write(StorageKeys.userId, demoUser.id);
      await _secureStorage.write(StorageKeys.userRole, demoUser.role.value);
      await _local.cacheUser(
        UserDto(
          id: demoUser.id,
          name: demoUser.name,
          email: demoUser.email,
          phone: '',
          role: demoUser.role,
        ),
      );
      return Success(demoUser);
    }

    try {
      final dto = await _remote.getUserProfile();
      final user = _mapper.toUser(dto);
      await _secureStorage.write(StorageKeys.userId, user.id);
      await _secureStorage.write(StorageKeys.userRole, user.role.value);
      await _local.cacheUser(dto);
      return Success(user);
    } catch (e, stack) {
      final cached = _local.getCachedUser();
      if (cached != null) return Success(_mapper.toUser(cached));
      return Error(ExceptionHandler.handle(e, stack));
    }
  }

  @override
  Future<Result<AppVersionInfo>> checkAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 1;
      final data = await _remote.checkAppVersion(
        versionCode: currentCode,
        platform: 'mobile',
      );
      final dto = AppVersionDto.fromJson(data);
      return Success(AppVersionInfo(
        minimumVersionCode: dto.minimumVersionCode,
        latestVersionCode: dto.latestVersionCode,
        forceUpdate: dto.forceUpdate,
        updateUrl: dto.updateUrl,
        releaseNotes: dto.message,
      ));
    } catch (e, stack) {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 1;
      return Success(AppVersionInfo(
        minimumVersionCode: 1,
        latestVersionCode: currentCode,
        forceUpdate: false,
      ));
    }
  }

  @override
  Future<UserRole?> getCachedUserRole() async {
    final role = await _secureStorage.read(StorageKeys.userRole);
    if (role == null) return null;
    return UserRole.fromString(role);
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final cached = _local.getCachedUser();
    return cached != null ? _mapper.toUser(cached) : null;
  }

  @override
  Future<bool> hasValidSession() => _tokenHandler.hasValidAccessToken();

  @override
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(StorageKeys.biometricEnabled);
    return value == 'true';
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(StorageKeys.biometricEnabled, enabled.toString());
  }

  Future<bool> _isDemoMode() async {
    final savedPhone = await _secureStorage.read(StorageKeys.lastLoginEmail);
    final lowerPhone = savedPhone?.trim().toLowerCase();
    return lowerPhone == _demoClientPhone ||
           lowerPhone == _demoStaffPhone ||
           lowerPhone == _demoRmPhone;
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Ignore logout API errors
    } finally {
      await _tokenHandler.clearTokens();
      await _secureStorage.delete(StorageKeys.userId);
      await _secureStorage.delete(StorageKeys.userRole);
      await _local.clearUser();
    }
  }
}
