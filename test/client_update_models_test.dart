import 'package:flutter_test/flutter_test.dart';
import 'package:homegennyapp/features/care/domain/client_update_models.dart';

void main() {
  final feed = ClientUpdatesFeed.fromJson({
    'items': [
      {
        'type': 'CARE_PLAN',
        'id': 'plan-2',
        'version': 2,
        'placement_id': 'p-1',
        'client_name': 'Kumar family',
        'title': 'Care plan changed (v2)',
        'changes': ['Medicine added: Amlodipine 5 mg at 21:00', 'Check stopped: Pulse at 09:00'],
        'at': '2026-10-13T08:00:00.000Z',
        'seen_at': '2026-10-13T08:05:00.000Z',
        'acknowledged_at': null,
      },
      {
        'type': 'MEAL_FEEDBACK',
        'id': 'fb-1',
        'version': 1,
        'placement_id': 'p-2',
        'client_name': null,
        'title': '2026-10-12 lunch: 2/5',
        // The backend drops empty parts, but be safe about blanks.
        'changes': ['too spicy', ''],
        'at': '2026-10-12T13:00:00.000Z',
        'seen_at': '2026-10-12T13:01:00.000Z',
        'acknowledged_at': '2026-10-12T14:00:00.000Z',
      },
    ],
    'unread': 1,
  });

  test('decodes the feed with backend-written changes as-is', () {
    expect(feed.unread, 1);
    final plan = feed.items.first;
    expect(plan.type, ClientUpdateType.carePlan);
    expect(plan.version, 2);
    expect(plan.isRead, isFalse);
    expect(plan.changes, ['Medicine added: Amlodipine 5 mg at 21:00', 'Check stopped: Pulse at 09:00']);
    expect(plan.seenAt, isNotNull);
  });

  test('blank change lines are dropped; read state follows acknowledged_at', () {
    final fb = feed.items.last;
    expect(fb.changes, ['too spicy']);
    expect(fb.isRead, isTrue);
    expect(fb.clientName, isNull);
  });

  test('markedRead keeps the identity used by Mark as read', () {
    final read = feed.items.first.markedRead();
    expect(read.isRead, isTrue);
    expect((read.type, read.id, read.version), ('CARE_PLAN', 'plan-2', 2));
  });
}
