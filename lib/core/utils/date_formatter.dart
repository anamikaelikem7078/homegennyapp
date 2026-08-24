import 'package:intl/intl.dart';

/// Formats backend ISO-8601 timestamps for display.
abstract final class DateFormatter {
  /// e.g. `2026-08-24T09:31:27.123Z` -> `24 Aug, 9:31 AM`. Falls back to the
  /// raw string if it isn't a parseable timestamp, and to [fallback] if null.
  static String timestamp(String? isoTimestamp, {String fallback = '--:--'}) {
    if (isoTimestamp == null) return fallback;
    final parsed = DateTime.tryParse(isoTimestamp);
    if (parsed == null) return isoTimestamp;
    return DateFormat('d MMM, h:mm a').format(parsed.toLocal());
  }

  /// Time-only variant for contexts that already show the date separately
  /// (e.g. a history row titled with its own date).
  static String time(String? isoTimestamp, {String fallback = '--:--'}) {
    if (isoTimestamp == null) return fallback;
    final parsed = DateTime.tryParse(isoTimestamp);
    if (parsed == null) return isoTimestamp;
    return DateFormat('h:mm a').format(parsed.toLocal());
  }
}
