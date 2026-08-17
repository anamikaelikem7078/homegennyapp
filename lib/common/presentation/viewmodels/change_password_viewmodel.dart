import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/utils/result.dart';
import '../../domain/repositories/auth_repository.dart';

class ChangePasswordViewModel extends StateNotifier<ChangePasswordState> {
  ChangePasswordViewModel(this._repository) : super(const ChangePasswordState());

  final AuthRepository _repository;

  Future<bool> changePassword({
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.changePassword(
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

class ChangePasswordState {
  const ChangePasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool success;

  ChangePasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      success: success ?? this.success,
    );
  }
}

final changePasswordViewModelProvider =
    StateNotifierProvider.autoDispose<ChangePasswordViewModel, ChangePasswordState>((ref) {
  return ChangePasswordViewModel(ref.watch(authRepositoryProvider));
});
