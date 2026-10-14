/// "New from the family": every input the client made for their staff
/// (care plan, food profile, menu, meal rating, instruction), newest first.
/// Opening the feed marks items seen; only "Mark as read" acknowledges.
library;

abstract final class ClientUpdateType {
  static const carePlan = 'CARE_PLAN';
  static const foodProfile = 'FOOD_PROFILE';
  static const menu = 'MENU';
  static const mealFeedback = 'MEAL_FEEDBACK';
  static const instruction = 'INSTRUCTION';
}

class ClientUpdate {
  const ClientUpdate({
    required this.type,
    required this.id,
    required this.version,
    required this.placementId,
    required this.title,
    this.clientName,
    this.changes = const [],
    this.at,
    this.seenAt,
    this.acknowledgedAt,
  });

  factory ClientUpdate.fromJson(Map<String, dynamic> j) => ClientUpdate(
        type: '${j['type'] ?? ''}',
        id: '${j['id'] ?? ''}',
        version: (j['version'] as num?)?.toInt() ?? 1,
        placementId: '${j['placement_id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        clientName: j['client_name'] as String?,
        // Written by the backend — shown as-is, never diffed in the app.
        changes: [for (final c in (j['changes'] is List ? j['changes'] as List : const [])) if ('$c'.trim().isNotEmpty) '$c'],
        at: DateTime.tryParse('${j['at'] ?? ''}')?.toLocal(),
        seenAt: DateTime.tryParse('${j['seen_at'] ?? ''}')?.toLocal(),
        acknowledgedAt: DateTime.tryParse('${j['acknowledged_at'] ?? ''}')?.toLocal(),
      );

  /// What "Mark as read" sends back, with [id].
  final String type;
  final String id;
  final int version;
  final String placementId;
  final String title;
  final String? clientName;
  final List<String> changes;
  final DateTime? at;
  final DateTime? seenAt;
  final DateTime? acknowledgedAt;

  bool get isRead => acknowledgedAt != null;

  /// Same item, now acknowledged — for an instant UI update.
  ClientUpdate markedRead() => ClientUpdate(
        type: type,
        id: id,
        version: version,
        placementId: placementId,
        title: title,
        clientName: clientName,
        changes: changes,
        at: at,
        seenAt: seenAt,
        acknowledgedAt: DateTime.now(),
      );
}

class ClientUpdatesFeed {
  const ClientUpdatesFeed({this.items = const [], this.unread = 0});
  factory ClientUpdatesFeed.fromJson(Map<String, dynamic> j) => ClientUpdatesFeed(
        items: [
          for (final e in (j['items'] as List?) ?? const [])
            if (e is Map<String, dynamic>) ClientUpdate.fromJson(e),
        ],
        unread: (j['unread'] as num?)?.toInt() ?? 0,
      );
  final List<ClientUpdate> items;
  final int unread;
}
