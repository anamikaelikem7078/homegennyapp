import 'package:hive/hive.dart';

part 'client_entity.g.dart';

@HiveType(typeId: 2)
class ClientEntity {
  ClientEntity({
    required this.id,
    required this.clientCode,
    required this.name,
    required this.phone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.address,
    this.assignedStaffIds = const [],
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String clientCode;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final String? email;

  @HiveField(5)
  final String? address;

  @HiveField(6)
  final List<String> assignedStaffIds;

  @HiveField(7)
  final String status;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;
}
