import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/utils/result.dart';
import '../../domain/repositories/auth_repository.dart';

/// Login screen ViewModel (MVVM).
class LoginViewModel extends StateNotifier<LoginState> {
  LoginViewModel(this._repository) : super(const LoginState());

  final AuthRepository _repository;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.login(email: email, password: password);

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false, loginSuccess: true);
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
  });

  final bool isLoading;
  final String? errorMessage;
  final bool loginSuccess;

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? loginSuccess,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      loginSuccess: loginSuccess ?? this.loginSuccess,
    );
  }
}

final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  return LoginViewModel(ref.watch(authRepositoryProvider));
});
