import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/utils/result.dart';
import '../../domain/repositories/auth_repository.dart';

/// OTP verification ViewModel (MVVM).
class OtpViewModel extends StateNotifier<OtpState> {
  OtpViewModel(this._repository) : super(const OtpState()) {
    _startResendTimer();
  }

  final AuthRepository _repository;
  Timer? _timer;

  void _startResendTimer() {
    _timer?.cancel();
    state = state.copyWith(resendSeconds: AppConstants.otpResendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendSeconds <= 0) {
        timer.cancel();
        return;
      }
      state = state.copyWith(resendSeconds: state.resendSeconds - 1);
    });
  }

  Future<bool> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.verifyOtp(phone: phone, otp: otp);

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false, verifySuccess: true);
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

  void resendOtp() {
    if (state.resendSeconds > 0) return;
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class OtpState {
  const OtpState({
    this.isLoading = false,
    this.errorMessage,
    this.verifySuccess = false,
    this.resendSeconds = AppConstants.otpResendSeconds,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool verifySuccess;
  final int resendSeconds;

  bool get canResend => resendSeconds <= 0;

  OtpState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? verifySuccess,
    int? resendSeconds,
  }) {
    return OtpState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      verifySuccess: verifySuccess ?? this.verifySuccess,
      resendSeconds: resendSeconds ?? this.resendSeconds,
    );
  }
}

final otpViewModelProvider =
    StateNotifierProvider.autoDispose<OtpViewModel, OtpState>((ref) {
  return OtpViewModel(ref.watch(authRepositoryProvider));
});
