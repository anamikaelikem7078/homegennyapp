/// User role enumeration for role-based navigation.
enum UserRole {
  staff('STAFF'),
  rm('RM'),
  client('CLIENT');

  const UserRole(this.value);

  final String value;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value.toUpperCase() == value?.toUpperCase(),
      orElse: () => UserRole.client,
    );
  }

  String get dashboardRoute => switch (this) {
        UserRole.staff => '/staff/home',
        UserRole.rm => '/rm/dashboard',
        UserRole.client => '/client/dashboard',
      };
}
