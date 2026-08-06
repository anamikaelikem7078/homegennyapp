import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/utils/result.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

/// Global authentication state.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  sessionExpired,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    final hasSession = await _repository.hasValidSession();
    if (!hasSession) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
      return;
    }

    final cachedUser = await _repository.getCachedUser();
    if (cachedUser != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: cachedUser,
      );
      return;
    }

    await fetchProfile();
  }

  Future<bool> fetchProfile() async {
    final result = await _repository.getUserProfile();
    return result.fold(
      onSuccess: (user) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return true;
      },
      onError: (failure) {
        state = AuthState(
          status: AuthStatus.sessionExpired,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  void setAuthenticated(UserModel user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  void setSessionExpired() {
    state = const AuthState(status: AuthStatus.sessionExpired);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider).user?.role;
});
