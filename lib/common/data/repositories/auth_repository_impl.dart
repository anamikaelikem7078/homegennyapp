import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/config/app_config.dart';
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
import '../../../common/domain/models/staff_entity.dart';

/// Authentication repository — remote + local cache.
class AuthRepositoryImpl implements AuthRepository {
  static const _demoPassword = 'HomeGenny@2024';

  static const _demoClientPhone = '9800000004';
  static const _demoStaffPhone = '9800000002';
  static const _demoRmPhone = '9800000001';

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
        _hiveService = hiveService,
        _remote = remote ?? AuthRemoteDataSource(dioClient),
        _local = local ?? AuthLocalDataSource(hiveService),
        _mapper = mapper ?? AuthMapper();

  final JwtTokenHandler _tokenHandler;
  final SecureStorageService _secureStorage;
  final HiveService _hiveService;
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
    final lowerPhone = phone.trim().toLowerCase();

    // Demo/local-prototype shortcuts only apply in dummy-API mode. Without
    // this guard, any real account using the backend's documented default
    // password (`HomeGenny@2024`, assigned to every Admin/HR-provisioned
    // user) collides with `isDemoCredentials` and gets a fake token instead
    // of a real login — this broke real RM login during testing.
    if (AppConfig.useDummyApi) {
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

      // Check if phone matches any staff in Hive (dummy password check for prototype)
      final isHiveStaff = _hiveService.staffBox.values
          .cast<StaffEntity>()
          .any((s) => s.phone == lowerPhone);
      if (isHiveStaff && password == '123456') {
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
    }

    try {
      final dto = await _remote.login(phone: phone, password: password);
      final tokens = _mapper.toTokens(dto);
      await _tokenHandler.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      await _secureStorage.write(StorageKeys.lastLoginEmail, phone);
      
      if (dto.user != null) {
        final user = _mapper.toUser(dto.user!);
        await _secureStorage.write(StorageKeys.userId, user.id);
        await _secureStorage.write(StorageKeys.userRole, user.role.value);
        await _local.cacheUser(dto.user!);
      }

      return Success(tokens);
    } catch (e, stack) {
      return Error(ExceptionHandler.handle(e, stack));
    }
  }

  @override
  Future<Result<bool>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final lowerPhone = phone.trim().toLowerCase();

    if (AppConfig.useDummyApi) {
      final isHiveStaff = _hiveService.staffBox.values
          .cast<StaffEntity>()
          .any((s) => s.phone == lowerPhone);

      if (lowerPhone == _demoClientPhone ||
          lowerPhone == _demoStaffPhone ||
          lowerPhone == _demoRmPhone ||
          isHiveStaff) {
        if (otp != '1234') {
          return const Error(AuthFailure(message: 'Invalid demo OTP. Use 1234.'));
        }
        return const Success(true);
      }
    }

    try {
      final valid = await _remote.verifyOtp(phone: phone, otp: otp);
      return Success(valid);
    } catch (e, stack) {
      return Error(ExceptionHandler.handle(e, stack));
    }
  }

  @override
  Future<Result<void>> forgotPassword({required String phone}) async {
    try {
      await _remote.forgotPassword(phone: phone);
      return const Success(null);
    } catch (e, stack) {
      return Error(ExceptionHandler.handle(e, stack));
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _remote.resetPassword(phone: phone, otp: otp, newPassword: newPassword);
      return const Success(null);
    } catch (e, stack) {
      return Error(ExceptionHandler.handle(e, stack));
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _remote.changePassword(otp: otp, newPassword: newPassword);
      return const Success(null);
    } catch (e, stack) {
      return Error(ExceptionHandler.handle(e, stack));
    }
  }

  @override
  Future<Result<UserModel>> getUserProfile() async {
    final savedPhone = await _secureStorage.read(StorageKeys.lastLoginEmail);
    final lowerPhone = savedPhone?.trim().toLowerCase();

    if (AppConfig.useDummyApi) {
      // Check if user is a created staff
      final staffMatches = _hiveService.staffBox.values
          .cast<StaffEntity>()
          .where((s) => s.phone == lowerPhone);

      if (staffMatches.isNotEmpty) {
        final staff = staffMatches.first;
        final user = UserModel(
          id: staff.id,
          name: staff.name,
          email: staff.email ?? '',
          role: UserRole.staff,
        );
        await _secureStorage.write(StorageKeys.userId, user.id);
        await _secureStorage.write(StorageKeys.userRole, user.role.value);
        return Success(user);
      }

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
