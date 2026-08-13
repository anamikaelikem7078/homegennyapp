import 'package:hive/hive.dart';

part 'staff_entity.g.dart';

@HiveType(typeId: 1)
class StaffEntity {
  StaffEntity({
    required this.id,
    required this.staffCode,
    required this.name,
    required this.phone,
    required this.status,
    required this.pipelineStage,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.profileImage,
    this.address,
    this.rmId,
    this.clientId,
    this.verification,
    this.training,
    this.videoCertification,
    this.agreement,
    this.deployment,
    this.trial,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String staffCode;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final String? email;

  @HiveField(5)
  final String? profileImage;

  @HiveField(6)
  final String? address;

  @HiveField(7)
  final String status;

  @HiveField(8)
  final String pipelineStage;

  @HiveField(9)
  final String? rmId;

  @HiveField(10)
  final String? clientId;

  @HiveField(11)
  final String? verification;

  @HiveField(12)
  final String? training;

  @HiveField(13)
  final String? videoCertification;

  @HiveField(14)
  final String? agreement;

  @HiveField(15)
  final String? deployment;

  @HiveField(16)
  final String? trial;

  @HiveField(17)
  final DateTime createdAt;

  @HiveField(18)
  final DateTime updatedAt;

  StaffEntity copyWith({
    String? id,
    String? staffCode,
    String? name,
    String? phone,
    String? email,
    String? profileImage,
    String? address,
    String? status,
    String? pipelineStage,
    String? rmId,
    String? clientId,
    String? verification,
    String? training,
    String? videoCertification,
    String? agreement,
    String? deployment,
    String? trial,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffEntity(
      id: id ?? this.id,
      staffCode: staffCode ?? this.staffCode,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      status: status ?? this.status,
      pipelineStage: pipelineStage ?? this.pipelineStage,
      rmId: rmId ?? this.rmId,
      clientId: clientId ?? this.clientId,
      verification: verification ?? this.verification,
      training: training ?? this.training,
      videoCertification: videoCertification ?? this.videoCertification,
      agreement: agreement ?? this.agreement,
      deployment: deployment ?? this.deployment,
      trial: trial ?? this.trial,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
