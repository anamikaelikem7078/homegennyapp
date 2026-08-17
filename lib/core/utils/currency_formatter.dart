import 'package:intl/intl.dart';

/// Formats numeric amounts as Indian Rupee currency strings (e.g. ₹18,540).
abstract final class CurrencyFormatter {
  static final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static String inr(num amount) => _inr.format(amount);
}
