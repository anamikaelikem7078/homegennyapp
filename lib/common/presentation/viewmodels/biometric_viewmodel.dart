import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/di/injection.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/utils/result.dart';
import '../../domain/repositories/auth_repository.dart';

/// Biometric authentication ViewModel (MVVM).
class BiometricViewModel extends StateNotifier<BiometricState> {
  BiometricViewModel(this._repository, this._localAuth)
      : super(const BiometricState());

  final AuthRepository _repository;
  final LocalAuthentication _localAuth;

  Future<bool> checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final biometrics = await _localAuth.getAvailableBiometrics();

      state = state.copyWith(
        isAvailable: canCheck && isDeviceSupported && biometrics.isNotEmpty,
        biometrics: biometrics,
      );
      return state.isAvailable;
    } catch (e) {
      state = state.copyWith(isAvailable: false);
      return false;
    }
  }

  Future<bool> authenticate() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access HomeGenny',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Authentication cancelled',
        );
        return false;
      }

      final hasSession = await _repository.hasValidSession();
      if (!hasSession) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No saved session. Please login with password.',
        );
        return false;
      }

      final result = await _repository.getUserProfile();
      return result.fold(
        onSuccess: (_) {
          state = state.copyWith(isLoading: false, authSuccess: true);
          return true;
        },
        onError: (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: ExceptionHandler.userMessage(failure),
          );
          return false;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Biometric authentication failed',
      );
      return false;
    }
  }
}

class BiometricState {
  const BiometricState({
    this.isLoading = false,
    this.isAvailable = false,
    this.authSuccess = false,
    this.errorMessage,
    this.biometrics = const [],
  });

  final bool isLoading;
  final bool isAvailable;
  final bool authSuccess;
  final String? errorMessage;
  final List<BiometricType> biometrics;

  BiometricState copyWith({
    bool? isLoading,
    bool? isAvailable,
    bool? authSuccess,
    String? errorMessage,
    List<BiometricType>? biometrics,
  }) {
    return BiometricState(
      isLoading: isLoading ?? this.isLoading,
      isAvailable: isAvailable ?? this.isAvailable,
      authSuccess: authSuccess ?? this.authSuccess,
      errorMessage: errorMessage,
      biometrics: biometrics ?? this.biometrics,
    );
  }
}

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

final biometricViewModelProvider =
    StateNotifierProvider<BiometricViewModel, BiometricState>((ref) {
  return BiometricViewModel(
    ref.watch(authRepositoryProvider),
    ref.watch(localAuthProvider),
  );
});
