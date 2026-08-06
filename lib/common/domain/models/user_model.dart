import 'package:equatable/equatable.dart';

import 'user_role.dart';

/// Authenticated user profile model.
class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? json['full_name'] as String? ?? '',
      role: UserRole.fromString(
        json['role'] as String? ?? json['user_role'] as String?,
      ),
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role.value,
        'phone': phone,
        'avatar_url': avatarUrl,
      };

  @override
  List<Object?> get props => [id, email, name, role, phone, avatarUrl];
}
