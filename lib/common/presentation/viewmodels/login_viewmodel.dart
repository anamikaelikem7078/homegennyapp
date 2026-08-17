import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/utils/result.dart';
import '../../domain/repositories/auth_repository.dart';

/// Login screen ViewModel (MVVM).
class LoginViewModel extends StateNotifier<LoginState> {
  LoginViewModel(this._repository) : super(const LoginState());

  final AuthRepository _repository;
  int _failedAttempts = 0;

  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    if (_failedAttempts >= 5) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Account locked due to too many failed attempts. Please try again later.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.login(phone: phone, password: password);

    return result.fold(
      onSuccess: (tokens) {
        _failedAttempts = 0;
        state = state.copyWith(
          isLoading: false, 
          loginSuccess: true,
          mustChangePassword: tokens.mustChangePassword,
        );
        return true;
      },
      onError: (failure) {
        _failedAttempts++;
        state = state.copyWith(
          isLoading: false,
          errorMessage: ExceptionHandler.userMessage(failure),
        );
        return false;
      },
    );
  }

  void reset() {
    state = const LoginState();
  }
}

class LoginState {
  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.loginSuccess = false,
    this.mustChangePassword = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool loginSuccess;
  final bool mustChangePassword;

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? loginSuccess,
    bool? mustChangePassword,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      loginSuccess: loginSuccess ?? this.loginSuccess,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}

final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  return LoginViewModel(ref.watch(authRepositoryProvider));
});
