import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/utils/result.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

/// Result of one `POST /auth/otp/verify`.
sealed class OtpVerifyOutcome {
  const OtpVerifyOutcome();
}

/// Signed in; tokens are saved and the user cached.
final class OtpVerified extends OtpVerifyOutcome {
  const OtpVerified(this.user);
  final UserModel user;
}

/// The number is new and no role was sent — ask "Client or Staff?" and
/// verify again with the same code (it stays valid).
final class OtpNeedsRole extends OtpVerifyOutcome {
  const OtpNeedsRole();
}

/// An office account (RM/BM/Admin/HR) — OTP login is refused.
final class OtpOfficeAccount extends OtpVerifyOutcome {
  const OtpOfficeAccount();
}

/// Anything else; the message is in [OtpState.errorMessage].
final class OtpFailed extends OtpVerifyOutcome {
  const OtpFailed();
}

/// OTP sign-in ViewModel (MVVM).
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

  Future<OtpVerifyOutcome> verify({
    required String phone,
    required String otp,
    UserRole? role,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.verifyLoginOtp(phone: phone, otp: otp, role: role);
    return result.fold(
      onSuccess: (user) {
        state = state.copyWith(isLoading: false);
        return OtpVerified(user);
      },
      onError: (failure) {
        final message = failure.message;
        final lower = message.toLowerCase();
        if (failure.code == '400' && lower.contains('not registered')) {
          state = state.copyWith(isLoading: false);
          return const OtpNeedsRole();
        }
        if (failure.code == '403' && lower.contains('office account')) {
          state = state.copyWith(isLoading: false);
          return const OtpOfficeAccount();
        }
        // An expired code (or one cancelled after 5 wrong tries) can only be
        // replaced — let "Resend" through straight away.
        final expired = lower.contains('expired') || lower.contains('request a new');
        state = state.copyWith(
          isLoading: false,
          errorMessage: ExceptionHandler.userMessage(failure),
          resendSeconds: expired ? 0 : null,
        );
        if (expired) _timer?.cancel();
        return const OtpFailed();
      },
    );
  }

  /// `POST /auth/otp/send` again — the new code replaces the old one.
  Future<bool> resend(String phone) async {
    if (!state.canResend || state.isLoading) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.sendLoginOtp(phone: phone);
    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        _startResendTimer();
        return true;
      },
      onError: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: ExceptionHandler.userMessage(failure));
        return false;
      },
    );
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
    this.resendSeconds = AppConstants.otpResendSeconds,
  });

  final bool isLoading;
  final String? errorMessage;
  final int resendSeconds;

  bool get canResend => resendSeconds <= 0;

  OtpState copyWith({
    bool? isLoading,
    String? errorMessage,
    int? resendSeconds,
  }) {
    return OtpState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      resendSeconds: resendSeconds ?? this.resendSeconds,
    );
  }
}

final otpViewModelProvider =
    StateNotifierProvider.autoDispose<OtpViewModel, OtpState>((ref) {
  return OtpViewModel(ref.watch(authRepositoryProvider));
});
