import 'package:flutter/foundation.dart';

/// User role enumeration for role-based navigation.
///
/// The backend issues more roles than this (see `prisma/schema.prisma`'s
/// `UserRole` enum: STAFF, CLIENT, RM, BM, FINANCE, ADMIN, TRAINER,
/// ASSESSOR, SUPPORT, HR). Only the ones the app has dedicated screens for
/// are listed here. `BM` and `ADMIN` are folded into [rm] rather than given
/// their own dashboard, because the backend's own route guards consistently
/// group them with RM for the operations this app exposes (e.g. the police
/// verification close endpoint documents "Roles allowed: RM, BM, ADMIN"),
/// so the RM dashboard is the correct destination for them, not a
/// dedicated one.
enum UserRole {
  staff('STAFF'),
  rm('RM'),
  bm('BM'),
  admin('ADMIN'),
  client('CLIENT');

  const UserRole(this.value);

  final String value;

  /// Falls back to [client] for an unrecognized/missing role string rather
  /// than throwing, so a single unexpected backend value doesn't crash
  /// login for every user. This is still a real misrouting risk for any
  /// backend role this enum doesn't list (FINANCE, TRAINER, ASSESSOR,
  /// SUPPORT, HR) — such an account will land on the client dashboard and
  /// every client-scoped API call will 401, since the backend's own
  /// role guard won't recognize them as CLIENT either — so it's logged
  /// loudly here to make that case visible during development/QA.
  static UserRole fromString(String? value) {
    final match = UserRole.values.where((role) => role.value.toUpperCase() == value?.toUpperCase());
    if (match.isEmpty) {
      debugPrint('UserRole.fromString: unrecognized role "$value" — defaulting to client. '
          'This will misroute the account into the client dashboard, where every '
          'client-scoped API call will 401 because the backend does not consider it a CLIENT.');
      return UserRole.client;
    }
    return match.first;
  }

  String get dashboardRoute => switch (this) {
        UserRole.staff => '/staff/home',
        UserRole.rm || UserRole.bm || UserRole.admin => '/rm/dashboard',
        UserRole.client => '/client/dashboard',
      };
}
