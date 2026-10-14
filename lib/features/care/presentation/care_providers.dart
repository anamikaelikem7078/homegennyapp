import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/result.dart';
import '../data/care_api.dart';
import '../domain/care_models.dart';
import '../domain/cook_models.dart';
import '../domain/client_update_models.dart';
import '../domain/instruction_models.dart';

export '../data/care_api.dart' show careApiProvider;

T _unwrap<T>(Result<T> r) => r.fold(onSuccess: (d) => d, onError: (f) => throw Exception(f.message));

/// India time — care dates and times are IST regardless of the phone's zone.
DateTime careNowIst() => DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

String careYmd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String careTodayIst() => careYmd(careNowIst());
String careYesterdayIst() => careYmd(careNowIst().subtract(const Duration(days: 1)));

// The care screens are short-lived and the data moves (ticks, new plan
// versions), so everything is autoDispose: opening a screen fetches fresh.

final carePlanProvider = FutureProvider.autoDispose.family<CarePlanView, String>(
  (ref, pid) async => _unwrap(await ref.watch(careApiProvider).getPlan(pid)),
);

final careDayProvider = FutureProvider.autoDispose.family<CareDay, ({String pid, String? date})>(
  (ref, k) async => _unwrap(await ref.watch(careApiProvider).getDay(k.pid, date: k.date)),
);

final careHistoryProvider = FutureProvider.autoDispose.family<CareHistory, ({String pid, int days})>(
  (ref, k) async {
    final to = careNowIst();
    return _unwrap(await ref.watch(careApiProvider).getHistory(
          k.pid,
          from: careYmd(to.subtract(Duration(days: k.days - 1))),
          to: careYmd(to),
        ));
  },
);

final staffCareTodayProvider = FutureProvider.autoDispose<StaffCareToday>(
  (ref) async => _unwrap(await ref.watch(careApiProvider).staffToday()),
);

/// A stored care file (photo, prescription). Kept for the session — a file
/// id never changes content.
final careFileBytesProvider = FutureProvider.family<Uint8List, String>(
  (ref, id) async => Uint8List.fromList(_unwrap(await ref.watch(careApiProvider).fileBytes(id))),
);

// ── Cook ──

final clientFoodProfileProvider = FutureProvider.autoDispose<ClientFoodProfileView>(
  (ref) async => _unwrap(await ref.watch(careApiProvider).getClientFoodProfile()),
);

final placementFoodProfileProvider = FutureProvider.autoDispose.family<FoodProfile?, String>(
  (ref, pid) async => _unwrap(await ref.watch(careApiProvider).getPlacementFoodProfile(pid)),
);

/// [week] is any date in the week (YYYY-MM-DD).
final menuWeekProvider = FutureProvider.autoDispose.family<MenuWeek, ({String pid, String week})>(
  (ref, k) async => _unwrap(await ref.watch(careApiProvider).getMenu(k.pid, week: k.week)),
);

final mealsProvider = FutureProvider.autoDispose.family<MealsView, ({String pid, int days})>(
  (ref, k) async {
    final to = careNowIst();
    return _unwrap(await ref.watch(careApiProvider).getMeals(
          k.pid,
          from: careYmd(to.subtract(Duration(days: k.days - 1))),
          to: careYmd(to),
        ));
  },
);

final cookTodayProvider = FutureProvider.autoDispose<CookToday>(
  (ref) async => _unwrap(await ref.watch(careApiProvider).cookToday()),
);

/// Monday of the IST week containing [d].
DateTime careWeekStart(DateTime d) => DateTime.utc(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

// ── Instructions ──

final placementInstructionsProvider = FutureProvider.autoDispose.family<List<Instruction>, String>(
  (ref, pid) async => _unwrap(await ref.watch(careApiProvider).getInstructions(pid)),
);

final staffInstructionsProvider = FutureProvider.autoDispose<List<Instruction>>(
  (ref) async => _unwrap(await ref.watch(careApiProvider).staffInstructions()),
);

// ── New from the family ──

final clientUpdatesProvider = FutureProvider.autoDispose<ClientUpdatesFeed>(
  (ref) async => _unwrap(await ref.watch(careApiProvider).clientUpdates()),
);

final clientUpdatesUnreadProvider = FutureProvider.autoDispose<int>(
  (ref) async => _unwrap(await ref.watch(careApiProvider).clientUpdatesUnreadCount()),
);

/// Everything a "Mark as read" can change on the staff side.
void invalidateAfterAck(WidgetRef ref) {
  ref
    ..invalidate(clientUpdatesProvider)
    ..invalidate(clientUpdatesUnreadProvider)
    ..invalidate(staffCareTodayProvider)
    ..invalidate(carePlanProvider)
    ..invalidate(staffInstructionsProvider)
    ..invalidate(cookTodayProvider);
}
