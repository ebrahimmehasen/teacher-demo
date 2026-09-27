import 'package:intl/intl.dart';

import '../../data/models/clock_time.dart';

abstract final class AppDates {
  /// Display order of the Egyptian week (Saturday first), as [DateTime.weekday] values.
  static const weekOrder = [
    DateTime.saturday,
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];

  static const _weekdayNames = {
    DateTime.saturday: 'السبت',
    DateTime.sunday: 'الأحد',
    DateTime.monday: 'الاثنين',
    DateTime.tuesday: 'الثلاثاء',
    DateTime.wednesday: 'الأربعاء',
    DateTime.thursday: 'الخميس',
    DateTime.friday: 'الجمعة',
  };

  static String weekdayName(int weekday) => _weekdayNames[weekday]!;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Billing month key in `yyyy-MM` format.
  static String monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  static DateTime parseMonthKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  static DateTime addMonths(DateTime d, int months) => DateTime(d.year, d.month + months, 1);

  /// e.g. "السبت 27 سبتمبر" with Western digits.
  static String dayMonth(DateTime d) => westernDigits(DateFormat('EEEE d MMMM', 'ar').format(d));

  /// e.g. "27/09/2026".
  static String short(DateTime d) => DateFormat('dd/MM/yyyy', 'en').format(d);

  /// e.g. "سبتمبر 2026".
  static String monthYear(DateTime d) => westernDigits(DateFormat('MMMM y', 'ar').format(d));

  /// e.g. "5:30 م".
  static String time(DateTime d) {
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour12:$minute ${d.hour < 12 ? 'ص' : 'م'}';
  }

  /// e.g. ClockTime(17, 0) ⇒ "5:00 م".
  static String clock(ClockTime t) => time(DateTime(2000, 1, 1, t.hour, t.minute));

  /// e.g. "27/9".
  static String dayShort(DateTime d) => '${d.day}/${d.month}';

  static String westernDigits(String input) {
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final index = eastern.indexOf(String.fromCharCode(rune));
      buffer.write(index >= 0 ? index : String.fromCharCode(rune));
    }
    return buffer.toString();
  }
}
