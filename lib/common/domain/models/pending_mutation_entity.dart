import 'package:hive/hive.dart';

part 'pending_mutation_entity.g.dart';

@HiveType(typeId: 15)
class PendingMutationEntity {
  PendingMutationEntity({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.retryCount = 0,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String entityType;

  @HiveField(2)
  final String entityId;

  @HiveField(3)
  final String action;

  @HiveField(4)
  final String payload;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final int retryCount;

  @HiveField(7)
  final DateTime createdAt;
}
