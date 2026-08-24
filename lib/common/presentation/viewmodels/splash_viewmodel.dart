import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/network_info.dart';
import '../../domain/models/app_version_info.dart';
import '../../domain/models/user_role.dart';
import '../../../core/utils/result.dart';
import '../../domain/repositories/auth_repository.dart';

/// Splash flow orchestration states.
enum SplashDestination {
  noInternet,
  updateRequired,
  login,
  biometricLogin,
  staffDashboard,
  rmDashboard,
  clientDashboard,
  sessionExpired,
}

class SplashResult {
  const SplashResult({
    required this.destination,
    this.updateUrl,
  });

  final SplashDestination destination;
  final String? updateUrl;
}

/// ViewModel for splash screen authentication bootstrap flow.
class SplashViewModel {
  SplashViewModel({
    required AuthRepository authRepository,
    required NetworkInfo networkInfo,
  })  : _authRepository = authRepository,
        _networkInfo = networkInfo;

  final AuthRepository _authRepository;
  final NetworkInfo _networkInfo;

  Future<SplashResult> initialize() async {
    await Future<void>.delayed(AppConstants.splashMinDuration);

    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const SplashResult(destination: SplashDestination.noInternet);
    }

    final versionResult = await _checkVersion();
    if (versionResult != null) {
      return versionResult;
    }

    final hasSession = await _authRepository.hasValidSession();
    if (!hasSession) {
      final biometricEnabled = await _authRepository.isBiometricEnabled();
      if (biometricEnabled) {
        return const SplashResult(destination: SplashDestination.biometricLogin);
      }
      return const SplashResult(destination: SplashDestination.login);
    }

    final profileResult = await _authRepository.getUserProfile();
    return profileResult.fold(
      onSuccess: (user) {
        return SplashResult(destination: _roleDestination(user.role));
      },
      onError: (_) {
        return const SplashResult(destination: SplashDestination.sessionExpired);
      },
    );
  }

  Future<SplashResult?> _checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 1;

      final result = await _authRepository.checkAppVersion();
      return result.fold(
        onSuccess: (AppVersionInfo info) {
          if (info.requiresUpdate(currentCode)) {
            return SplashResult(
              destination: SplashDestination.updateRequired,
              updateUrl: info.updateUrl,
            );
          }
          return null;
        },
        onError: (_) => null,
      );
    } catch (_) {
      return null;
    }
  }

  SplashDestination _roleDestination(UserRole role) {
    return switch (role) {
      UserRole.staff => SplashDestination.staffDashboard,
      UserRole.rm || UserRole.bm || UserRole.admin => SplashDestination.rmDashboard,
      UserRole.client => SplashDestination.clientDashboard,
    };
  }
}

final splashViewModelProvider = Provider<SplashViewModel>((ref) {
  return SplashViewModel(
    authRepository: ref.watch(authRepositoryProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});
