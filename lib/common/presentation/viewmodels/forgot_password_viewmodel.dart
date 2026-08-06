import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/utils/result.dart';
import '../../domain/repositories/auth_repository.dart';

/// Forgot password ViewModel (MVVM).
class ForgotPasswordViewModel extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordViewModel(this._repository) : super(const ForgotPasswordState());

  final AuthRepository _repository;

  Future<bool> sendResetLink({required String email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.forgotPassword(email: email);

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false, emailSent: true);
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
}

class ForgotPasswordState {
  const ForgotPasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.emailSent = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool emailSent;

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? emailSent,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      emailSent: emailSent ?? this.emailSent,
    );
  }
}

final forgotPasswordViewModelProvider =
    StateNotifierProvider<ForgotPasswordViewModel, ForgotPasswordState>((ref) {
  return ForgotPasswordViewModel(ref.watch(authRepositoryProvider));
});
