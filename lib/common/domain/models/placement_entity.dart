import 'package:hive/hive.dart';

part 'placement_entity.g.dart';

@HiveType(typeId: 9)
class PlacementEntity {
  PlacementEntity({
    required this.id,
    required this.staffId,
    required this.clientId,
    required this.deploymentDate,
    required this.status,
    this.trialDate,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String staffId;

  @HiveField(2)
  final String clientId;

  @HiveField(3)
  final DateTime deploymentDate;

  @HiveField(4)
  final DateTime? trialDate;

  @HiveField(5)
  final String status;
}
