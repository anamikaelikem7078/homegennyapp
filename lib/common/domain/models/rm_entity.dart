import 'package:hive/hive.dart';

part 'rm_entity.g.dart';

@HiveType(typeId: 3)
class RMEntity {
  RMEntity({
    required this.id,
    required this.rmCode,
    required this.name,
    required this.phone,
    required this.status,
    this.email,
    this.branch,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String rmCode;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final String? email;

  @HiveField(5)
  final String? branch;

  @HiveField(6)
  final String status;
}
