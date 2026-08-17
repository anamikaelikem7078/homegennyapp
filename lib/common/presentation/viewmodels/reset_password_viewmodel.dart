import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/utils/result.dart';
import '../../domain/repositories/auth_repository.dart';

class ResetPasswordViewModel extends StateNotifier<ResetPasswordState> {
  ResetPasswordViewModel(this._repository) : super(const ResetPasswordState());

  final AuthRepository _repository;

  Future<bool> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.resetPassword(
      phone: phone,
      otp: otp,
      newPassword: newPassword,
    );

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false, success: true);
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

class ResetPasswordState {
  const ResetPasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool success;

  ResetPasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
  }) {
    return ResetPasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      success: success ?? this.success,
    );
  }
}

final resetPasswordViewModelProvider =
    StateNotifierProvider.autoDispose<ResetPasswordViewModel, ResetPasswordState>((ref) {
  return ResetPasswordViewModel(ref.watch(authRepositoryProvider));
});
