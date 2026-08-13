import 'package:hive/hive.dart';

part 'agreement_entity.g.dart';

@HiveType(typeId: 8)
class AgreementEntity {
  AgreementEntity({
    required this.id,
    required this.staffId,
    required this.status,
    this.signaturePath,
    this.signedAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String staffId;

  @HiveField(2)
  final String status;

  @HiveField(3)
  final String? signaturePath;

  @HiveField(4)
  final DateTime? signedAt;
}
