import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/domain/models/user_role.dart';
import '../../common/presentation/providers/auth_provider.dart';
import '../config/app_config.dart';
import '../di/injection.dart';
import '../network/api_service.dart';
import '../router/app_routes.dart';
import 'onboarding_models.dart';

class OnboardingRemoteDataSource extends BaseRemoteDataSource {
  OnboardingRemoteDataSource(super.dio);

  Future<OnboardingStatus> getOnboarding() async =>
      OnboardingStatus.fromJson(await getJson('/me/onboarding'));

  Future<List<CityOption>> getCities() async {
    final json = await getJson('/meta/cities');
    final list = (json['cities'] ?? json['items']) as List? ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) CityOption.fromJson(e),
    ].where((c) => c.city.isNotEmpty).toList();
  }
}

final onboardingRemoteDataSourceProvider = Provider<OnboardingRemoteDataSource>((ref) {
  return OnboardingRemoteDataSource(ref.watch(dioClientProvider));
});

/// `GET /me/onboarding` for the signed-in CLIENT / STAFF account. Re-fetched
/// whenever the account changes; invalidate it after a profile save/submit.
/// Other roles (and dummy mode) are never gated.
final onboardingProvider = FutureProvider<OnboardingStatus>((ref) async {
  final user = ref.watch(authProvider.select((s) => s.user));
  if (AppConfig.useDummyApi || user == null) return OnboardingStatus.ready;
  if (user.role != UserRole.staff && user.role != UserRole.client) return OnboardingStatus.ready;
  return ref.watch(onboardingRemoteDataSourceProvider).getOnboarding();
});

/// True only once the server has confirmed the profile is incomplete — while
/// loading or on error nothing is locked here (the server still refuses).
final profileLockedProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider).valueOrNull?.isLocked ?? false;
});

/// `GET /meta/cities` — fetched once per session.
final citiesProvider = FutureProvider<List<CityOption>>((ref) {
  return ref.watch(onboardingRemoteDataSourceProvider).getCities();
});

/// Which wizard step holds each server field name.
int staffWizardStepFor(String field) => switch (field) {
      'full_name' || 'date_of_birth' || 'gender' || 'series' => 0,
      'address' || 'city' || 'area' || 'pincode' => 1,
      _ => 2, // emergency_contact*, languages, experience
    };

int clientWizardStepFor(String field) => switch (field) {
      'name' || 'full_name' || 'email' => 0,
      _ => 1, // address, city, pincode
    };

/// The profile wizard for [role], opened at the step of the first [missing]
/// field. Null for roles without one.
String? profileWizardRoute(UserRole? role, [List<String> missing = const []]) {
  switch (role) {
    case UserRole.staff:
      final step = missing.isEmpty ? 0 : missing.map(staffWizardStepFor).reduce((a, b) => a < b ? a : b);
      return '${AppRoutes.staffCompleteProfile}?step=$step';
    case UserRole.client:
      final step = missing.isEmpty ? 0 : missing.map(clientWizardStepFor).reduce((a, b) => a < b ? a : b);
      return '${AppRoutes.clientCompleteProfile}?step=$step';
    default:
      return null;
  }
}

/// Where to land after login / on app start: the profile wizard while
/// `next_step` is COMPLETE_PROFILE, else the role's home. Call once the
/// tokens are saved. If `/me/onboarding` fails, the home opens — the
/// server still refuses actions, which opens the wizard then.
Future<String> landingRouteAfterLogin(OnboardingRemoteDataSource source, UserRole role) async {
  if (AppConfig.useDummyApi || (role != UserRole.staff && role != UserRole.client)) {
    return role.dashboardRoute;
  }
  try {
    final status = await source.getOnboarding();
    if (status.nextStep == OnboardingNextStep.completeProfile) {
      return profileWizardRoute(role, status.missing) ?? role.dashboardRoute;
    }
  } catch (_) {}
  return role.dashboardRoute;
}

/// Display name with the brief's fallback: name → phone → "Welcome".
String displayNameOr(String? name, String? phone) {
  if (name != null && name.trim().isNotEmpty) return name.trim();
  if (phone != null && phone.trim().isNotEmpty) return phone.trim();
  return 'Welcome';
}
