import '../../domain/models/user_role.dart';

/// Auth tokens DTO from API.
class AuthTokensDto {
  const AuthTokensDto({
    required this.accessToken,
    required this.refreshToken,
    this.mustChangePassword = false,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final bool mustChangePassword;
  final UserDto? user;

  factory AuthTokensDto.fromJson(Map<String, dynamic> json) => AuthTokensDto(
        accessToken: json['access_token'] as String? ?? json['accessToken'] as String? ?? '',
        refreshToken: json['refresh_token'] as String? ?? json['refreshToken'] as String? ?? '',
        mustChangePassword: json['must_change_password'] as bool? ?? json['mustChangePassword'] as bool? ?? false,
        user: json['user'] != null ? UserDto.fromJson(json['user']) : null,
      );

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'must_change_password': mustChangePassword,
        if (user != null) 'user': user!.toJson(),
      };
}

/// User profile DTO from API.
class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? avatarUrl;

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        role: UserRole.fromString(json['role'] as String?),
        avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.value,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
}

/// App version check DTO.
class AppVersionDto {
  const AppVersionDto({
    required this.minimumVersionCode,
    required this.latestVersionCode,
    required this.forceUpdate,
    this.updateUrl,
    this.message,
  });

  final int minimumVersionCode;
  final int latestVersionCode;
  final bool forceUpdate;
  final String? updateUrl;
  final String? message;

  factory AppVersionDto.fromJson(Map<String, dynamic> json) => AppVersionDto(
        minimumVersionCode: json['minimum_version_code'] as int? ??
            json['minimumVersionCode'] as int? ??
            1,
        latestVersionCode: json['latest_version_code'] as int? ??
            json['latestVersionCode'] as int? ??
            1,
        forceUpdate: json['force_update'] as bool? ?? json['forceUpdate'] as bool? ?? false,
        updateUrl: json['update_url'] as String? ?? json['updateUrl'] as String?,
        message: json['message'] as String?,
      );
}
