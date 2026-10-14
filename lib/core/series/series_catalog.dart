import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/injection.dart';
import '../network/api_service.dart';

/// Staff series, as `GET /meta/series` returns them. The backend decides which
/// are taken on right now, so pickers read it from there instead of keeping
/// their own list.
///
/// Series has two forms — never compare one against the other:
/// - long `value` (`series_db` on staff objects): UNSKILLED_CARE, SKILLED_CARE,
///   COOK, MAID, DRIVER
/// - short `short` (`series` on staff objects, and what `POST /rm/intake` and
///   `POST /auth/register/staff` take): UC, SC, CK, MAID, DR
class SeriesOption {
  const SeriesOption({
    required this.value,
    required this.short,
    required this.label,
    required this.active,
  });

  factory SeriesOption.fromJson(Map<String, dynamic> j) => SeriesOption(
        value: j['value'] as String? ?? '',
        short: j['short'] as String? ?? '',
        label: j['label'] as String? ?? '',
        active: j['active'] as bool? ?? false,
      );

  final String value;
  final String short;
  final String label;

  /// Whether a NEW staff member can be created in this series.
  final bool active;
}

class SeriesCatalog {
  const SeriesCatalog({required this.all, required this.stage25Enabled});

  /// Used until `/meta/series` answers, and if it can't. Mirrors the backend.
  static const fallback = SeriesCatalog(
    all: [
      SeriesOption(value: 'UNSKILLED_CARE', short: 'UC', label: 'Unskilled Caretaker', active: true),
      SeriesOption(value: 'SKILLED_CARE', short: 'SC', label: 'Skilled Caretaker', active: true),
      SeriesOption(value: 'COOK', short: 'CK', label: 'Cook', active: true),
      SeriesOption(value: 'MAID', short: 'MAID', label: 'Maid', active: false),
      SeriesOption(value: 'DRIVER', short: 'DR', label: 'Driver', active: false),
    ],
    stage25Enabled: false,
  );

  /// Every series, for lists and filters — paused ones still have staff.
  final List<SeriesOption> all;

  /// Whether the S2_5_ASSESS stage is in use.
  final bool stage25Enabled;

  /// Only what a NEW staff member may be created as.
  List<SeriesOption> get active => all.where((s) => s.active).toList();

  /// Finds a series by either form; null when unknown.
  SeriesOption? find(String? raw) {
    final s = raw?.trim().toUpperCase();
    if (s == null || s.isEmpty) return null;
    for (final o in all) {
      if (o.value == s || o.short == s) return o;
    }
    return null;
  }
}

class MetaRemoteDataSource extends BaseRemoteDataSource {
  MetaRemoteDataSource(super.dio);

  Future<SeriesCatalog> getSeries() async {
    final json = await getJson('/meta/series');
    final list = (json['series'] as List?) ?? const [];
    final all = [
      for (final e in list)
        if (e is Map<String, dynamic>) SeriesOption.fromJson(e),
    ].where((s) => s.value.isNotEmpty && s.short.isNotEmpty).toList();
    if (all.isEmpty) return SeriesCatalog.fallback;
    return SeriesCatalog(
      all: all,
      stage25Enabled: json['stage_2_5_enabled'] as bool? ?? false,
    );
  }
}

final metaRemoteDataSourceProvider = Provider<MetaRemoteDataSource>((ref) {
  return MetaRemoteDataSource(ref.watch(dioClientProvider));
});

/// Fetched once and kept for the session. Never errors: a failed call falls
/// back to UC / SC / CK as active.
final seriesCatalogFutureProvider = FutureProvider<SeriesCatalog>((ref) async {
  try {
    return await ref.watch(metaRemoteDataSourceProvider).getSeries();
  } catch (_) {
    return SeriesCatalog.fallback;
  }
});

/// The catalog to render right now — the fallback until the call answers.
final seriesCatalogProvider = Provider<SeriesCatalog>((ref) {
  return ref.watch(seriesCatalogFutureProvider).valueOrNull ?? SeriesCatalog.fallback;
});

/// Display helpers that accept either series form. An unknown value is shown
/// as-is with a neutral look — never mapped to another series.
abstract final class SeriesDisplay {
  static String? _short(String? raw) =>
      SeriesCatalog.fallback.find(raw)?.short;

  /// Short code (UC, SC, CK, MAID, DR), or the raw value if unknown.
  static String code(String? raw) => _short(raw) ?? (raw ?? '');

  /// Human label ("Skilled Caretaker"), or the raw value if unknown.
  static String label(String? raw) =>
      SeriesCatalog.fallback.find(raw)?.label ?? (raw ?? '');

  /// Whether the series is paused for new staff (MAID, DR).
  static bool isPaused(String? raw) =>
      SeriesCatalog.fallback.find(raw)?.active == false;

  static Color color(String? raw) => switch (_short(raw)) {
        'UC' => const Color(0xFFF97316),
        'SC' => const Color(0xFF8B5CF6),
        'CK' => const Color(0xFFD97706),
        'MAID' => const Color(0xFF06B6D4),
        'DR' => const Color(0xFF3B82F6),
        _ => const Color(0xFF6B7280),
      };

  static IconData icon(String? raw) => switch (_short(raw)) {
        'UC' => Icons.handyman_rounded,
        'SC' => Icons.medical_services_rounded,
        'CK' => Icons.restaurant_rounded,
        'MAID' => Icons.cleaning_services_rounded,
        'DR' => Icons.directions_car_rounded,
        _ => Icons.person_rounded,
      };
}
