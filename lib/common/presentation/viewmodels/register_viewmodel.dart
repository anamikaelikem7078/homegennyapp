import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/utils/result.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// Staff + client self-registration ViewModel (MVVM). Both flows share one
/// state shape and error-handling path since they both return the same
/// `LoginResponse` shape and sign the account in immediately on success.
class RegisterViewModel extends StateNotifier<RegisterState> {
  RegisterViewModel(this._repository) : super(const RegisterState());

  final AuthRepository _repository;

  Future<bool> registerStaff({
    required String fullName,
    required String phone,
    String? alternatePhone,
    String? email,
    required String password,
    required String dateOfBirth,
    required String gender,
    required String address,
    String? city,
    String? stateName,
    String? pincode,
    required String series,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.registerStaff(
      fullName: fullName,
      phone: phone,
      alternatePhone: alternatePhone,
      email: email,
      password: password,
      dateOfBirth: dateOfBirth,
      gender: gender,
      address: address,
      city: city,
      stateName: stateName,
      pincode: pincode,
      series: series,
    );
    return _handleResult(result);
  }

  Future<bool> registerCustomer({
    required String fullName,
    required String phone,
    String? email,
    required String password,
    String? businessName,
    required String panCard,
    required String address,
    String? city,
    String? stateName,
    String? pincode,
    String? gstn,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.registerCustomer(
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
      businessName: businessName,
      panCard: panCard,
      address: address,
      city: city,
      stateName: stateName,
      pincode: pincode,
      gstn: gstn,
    );
    return _handleResult(result);
  }

  bool _handleResult(Result<UserModel> result) {
    return result.fold(
      onSuccess: (user) {
        state = state.copyWith(isLoading: false, success: true, user: user);
        return true;
      },
      onError: (failure) {
        // A 403 here means the applicant matched the restricted list — the
        // backend's message text must not be surfaced verbatim to the user.
        final message = failure.code == '403'
            ? "We couldn't complete your registration. Please contact your nearest branch for assistance."
            : ExceptionHandler.userMessage(failure);
        state = state.copyWith(isLoading: false, errorMessage: message);
        return false;
      },
    );
  }

  void reset() {
    state = const RegisterState();
  }
}

class RegisterState {
  const RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
    this.user,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool success;
  final UserModel? user;

  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
    UserModel? user,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      success: success ?? this.success,
      user: user ?? this.user,
    );
  }
}

final registerViewModelProvider =
    StateNotifierProvider.autoDispose<RegisterViewModel, RegisterState>((ref) {
  return RegisterViewModel(ref.watch(authRepositoryProvider));
});
