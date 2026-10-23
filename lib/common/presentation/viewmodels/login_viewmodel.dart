import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/utils/result.dart';
import '../../domain/models/otp_send_result.dart';
import '../../domain/repositories/auth_repository.dart';

/// Login screen ViewModel (MVVM) — mobile number only; the code is checked
/// on the OTP screen.
class LoginViewModel extends StateNotifier<LoginState> {
  LoginViewModel(this._repository) : super(const LoginState());

  final AuthRepository _repository;

  /// `POST /auth/otp/send`. Null on error (the message is in state).
  Future<OtpSendResult?> sendOtp(String phone) async {
    state = const LoginState(isLoading: true);
    final result = await _repository.sendLoginOtp(phone: phone);
    return result.fold(
      onSuccess: (sent) {
        state = const LoginState();
        return sent;
      },
      onError: (failure) {
        state = LoginState(errorMessage: ExceptionHandler.userMessage(failure));
        return null;
      },
    );
  }
}

class LoginState {
  const LoginState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;
}

final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginViewModel, LoginState>((ref) {
  return LoginViewModel(ref.watch(authRepositoryProvider));
});
