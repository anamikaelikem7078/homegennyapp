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

  /// A check-in time that may be from an earlier day (a live-in stay or a
  /// night shift): `9:31 AM` today, `24 Oct, 8:00 PM` otherwise. Falls back
  /// to the raw string if it isn't a timestamp.
  static String since(String? isoTimestamp, {String fallback = '--:--'}) {
    if (isoTimestamp == null) return fallback;
    final parsed = DateTime.tryParse(isoTimestamp);
    if (parsed == null) return isoTimestamp;
    final local = parsed.toLocal();
    final now = DateTime.now();
    final today = local.year == now.year && local.month == now.month && local.day == now.day;
    return DateFormat(today ? 'h:mm a' : 'd MMM, h:mm a').format(local);
  }

  /// e.g. `15 Oct`.
  static String date(DateTime value) => DateFormat('d MMM').format(value);

  /// A calendar day, e.g. `2025-12-12` or `2025-12-12T00:00:00.000Z` ->
  /// `12 Dec 2025`. Falls back to the raw string if it isn't a date.
  static String day(String? value, {String fallback = '—'}) {
    if (value == null || value.isEmpty) return fallback;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    // Date-only strings are IST calendar dates; timestamps are shown local.
    final d = value.length <= 10 ? parsed : parsed.toLocal();
    return DateFormat('d MMM yyyy').format(d);
  }

  /// A billing month as the backend sends it (`12/2025`) -> `Dec 2025`.
  /// Falls back to the raw string.
  static String month(String billingMonth) {
    final parts = billingMonth.split('/');
    if (parts.length != 2) return billingMonth;
    final m = int.tryParse(parts[0]);
    final y = int.tryParse(parts[1]);
    if (m == null || y == null || m < 1 || m > 12) return billingMonth;
    return DateFormat('MMM yyyy').format(DateTime(y, m));
  }

  /// The days an invoice covers (`YYYY-MM-DD` pair) — a client can have
  /// several invoices in one month, so this, not the month, tells them
  /// apart: `01–07 Dec 2025`, `28 Nov – 04 Dec 2025`,
  /// `28 Dec 2025 – 03 Jan 2026`. Without both dates (very old invoices)
  /// falls back to [billingMonth] via [month].
  static String period(String? from, String? to, {String billingMonth = ''}) {
    final a = from == null || from.isEmpty ? null : DateTime.tryParse(from);
    final b = to == null || to.isEmpty ? null : DateTime.tryParse(to);
    if (a == null || b == null) return month(billingMonth);
    final dd = DateFormat('dd');
    if (a.year == b.year && a.month == b.month) {
      return '${dd.format(a)}–${dd.format(b)} ${DateFormat('MMM yyyy').format(b)}';
    }
    if (a.year == b.year) {
      return '${DateFormat('dd MMM').format(a)} – ${DateFormat('dd MMM yyyy').format(b)}';
    }
    final full = DateFormat('dd MMM yyyy');
    return '${full.format(a)} – ${full.format(b)}';
  }
}
