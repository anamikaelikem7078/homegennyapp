import 'package:hive/hive.dart';

part 'document_entity.g.dart';

@HiveType(typeId: 5)
class DocumentEntity {
  DocumentEntity({
    required this.id,
    required this.staffId,
    required this.type,
    required this.name,
    required this.filePath,
    required this.status,
    required this.uploadedAt,
    this.rejectionReason,
    this.reviewedAt,
    this.reviewerId,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String staffId;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final String name;

  @HiveField(4)
  final String filePath;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final String? rejectionReason;

  @HiveField(7)
  final DateTime uploadedAt;

  @HiveField(8)
  final DateTime? reviewedAt;

  @HiveField(9)
  final String? reviewerId;

  DocumentEntity copyWith({
    String? id,
    String? staffId,
    String? type,
    String? name,
    String? filePath,
    String? status,
    String? rejectionReason,
    DateTime? uploadedAt,
    DateTime? reviewedAt,
    String? reviewerId,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      type: type ?? this.type,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewerId: reviewerId ?? this.reviewerId,
    );
  }
}
