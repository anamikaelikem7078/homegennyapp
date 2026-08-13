import 'package:uuid/uuid.dart';

import '../../../../common/domain/models/document_entity.dart';
import '../../../../common/domain/models/placement_entity.dart';
import '../../../../common/domain/models/staff_entity.dart';
import '../../../../common/domain/models/training_entity.dart';
import '../../../../common/domain/models/video_certification_entity.dart';
import '../../../../core/data/mutation_queue_service.dart';
import '../../../../core/storage/hive_service.dart';

class RmRepository {
  RmRepository({
    required this.hiveService,
    required this.mutationQueue,
  });

  final HiveService hiveService;
  final MutationQueueService mutationQueue;
  final _uuid = const Uuid();

  // --- Staff Management ---
  
  List<StaffEntity> getRmStaff(String rmId) {
    return hiveService.staffBox.values
        .cast<StaffEntity>()
        .where((staff) => staff.rmId == rmId)
        .toList();
  }

  StaffEntity? getStaffById(String id) {
    return hiveService.staffBox.get(id) as StaffEntity?;
  }

  Future<void> createStaff(StaffEntity staff) async {
    await hiveService.staffBox.put(staff.id, staff);
    await mutationQueue.queueMutation(
      entityType: 'StaffEntity',
      entityId: staff.id,
      action: 'CREATE',
      payload: staff.id,
    );
  }

  Future<void> updateStaff(StaffEntity staff) async {
    await hiveService.staffBox.put(staff.id, staff);
    await mutationQueue.queueMutation(
      entityType: 'StaffEntity',
      entityId: staff.id,
      action: 'UPDATE',
      payload: staff.id,
    );
  }

  // --- Documents & Verification ---

  Future<void> approveDocument(String docId, String rmId) async {
    final doc = hiveService.documentBox.get(docId) as DocumentEntity?;
    if (doc != null) {
      final updatedDoc = doc.copyWith(
        status: 'APPROVED',
        reviewedAt: DateTime.now(),
        reviewerId: rmId,
      );
      await hiveService.documentBox.put(docId, updatedDoc);
      await mutationQueue.queueMutation(
        entityType: 'DocumentEntity',
        entityId: docId,
        action: 'UPDATE',
        payload: docId,
      );
    }
  }

  Future<void> rejectDocument(String docId, String rmId, String reason) async {
    final doc = hiveService.documentBox.get(docId) as DocumentEntity?;
    if (doc != null) {
      final updatedDoc = doc.copyWith(
        status: 'REJECTED',
        reviewedAt: DateTime.now(),
        reviewerId: rmId,
        rejectionReason: reason,
      );
      await hiveService.documentBox.put(docId, updatedDoc);
      await mutationQueue.queueMutation(
        entityType: 'DocumentEntity',
        entityId: docId,
        action: 'UPDATE',
        payload: docId,
      );
    }
  }

  // --- Dashboard Stats ---
  
  Map<String, int> getDashboardStats(String rmId) {
    final staff = getRmStaff(rmId);
    
    int pipelineCount = staff.where((s) => s.status == 'PIPELINE' || s.status == 'AVAILABLE').length;
    int trialCount = staff.where((s) => s.pipelineStage == 'TRIAL').length;
    
    // In a real app, alerts would be calculated from missing docs, rejected videos, etc.
    int alertsCount = 0; 
    for (var s in staff) {
      if (s.pipelineStage == 'REGISTRATION') alertsCount++;
    }

    return {
      'totalStaff': staff.length,
      'pipeline': pipelineCount,
      'alerts': alertsCount,
      'trialsActive': trialCount,
    };
  }
}
