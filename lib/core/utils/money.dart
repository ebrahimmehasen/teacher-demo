import 'package:intl/intl.dart';

abstract final class Money {
  static final _whole = NumberFormat('#,##0', 'en');
  static final _fraction = NumberFormat('#,##0.##', 'en');

  /// e.g. 1250 ⇒ "1,250 ج.م" (Western digits).
  static String format(num amount) {
    final formatter = amount == amount.roundToDouble() ? _whole : _fraction;
    return '${formatter.format(amount)} ج.م';
  }
}
