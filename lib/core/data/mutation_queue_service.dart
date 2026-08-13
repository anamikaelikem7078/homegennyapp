import 'package:uuid/uuid.dart';

import '../../common/domain/models/pending_mutation_entity.dart';
import '../storage/hive_service.dart';

class MutationQueueService {
  MutationQueueService(this._hiveService);

  final HiveService _hiveService;
  final _uuid = const Uuid();

  Future<void> queueMutation({
    required String entityType,
    required String entityId,
    required String action,
    required String payload,
  }) async {
    final mutation = PendingMutationEntity(
      id: _uuid.v4(),
      entityType: entityType,
      entityId: entityId,
      action: action,
      payload: payload,
      status: 'SYNCED', // Auto-synced for demo mode
      createdAt: DateTime.now(),
    );

    await _hiveService.pendingMutationBox.put(mutation.id, mutation);
  }

  List<PendingMutationEntity> getPendingMutations() {
    return _hiveService.pendingMutationBox.values
        .cast<PendingMutationEntity>()
        .where((m) => m.status == 'PENDING')
        .toList();
  }

  Future<void> markAsSynced(String mutationId) async {
    final mutation = _hiveService.pendingMutationBox.get(mutationId) as PendingMutationEntity?;
    if (mutation != null) {
      final updated = PendingMutationEntity(
        id: mutation.id,
        entityType: mutation.entityType,
        entityId: mutation.entityId,
        action: mutation.action,
        payload: mutation.payload,
        status: 'SYNCED',
        createdAt: mutation.createdAt,
        retryCount: mutation.retryCount,
      );
      await _hiveService.pendingMutationBox.put(updated.id, updated);
    }
  }
}
