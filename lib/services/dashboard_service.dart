import '../core/utils/date_utils.dart';
import '../data/models/models.dart';
import 'payment_status_service.dart';
import 'pricing_service.dart';

class DailyAttendance {
  const DailyAttendance(this.day, this.attended, this.total);
  final DateTime day;
  final int attended;
  final int total;
  double get rate => total == 0 ? 0 : attended / total;
}

class TodayAttendance {
  const TodayAttendance({required this.attended, required this.expected});
  final int attended;
  final int expected;
}

/// Current-month billing of one enrollment.
class Billing {
  const Billing({
    required this.enrollment,
    required this.group,
    required this.grade,
    required this.price,
    required this.paid,
    required this.status,
  });

  final Enrollment enrollment;
  final Group group;
  final Grade grade;
  final double price;
  final double paid;
  final PaymentStatus status;
}

abstract final class DashboardService {
  static bool _attended(Attendance a) =>
      a.status == AttendanceStatus.present || a.status == AttendanceStatus.late;

  /// One entry per day in [from]..[to] that has attendance records.
  static List<DailyAttendance> dailyAttendance(
    Iterable<Attendance> records, {
    required DateTime from,
    required DateTime to,
  }) {
    final start = AppDates.dateOnly(from);
    final end = AppDates.dateOnly(to);
    final byDay = <DateTime, List<Attendance>>{};
    for (final a in records) {
      final day = AppDates.dateOnly(a.date);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      byDay.putIfAbsent(day, () => []).add(a);
    }
    final days = byDay.keys.toList()..sort();
    return [
      for (final day in days)
        DailyAttendance(day, byDay[day]!.where(_attended).length, byDay[day]!.length),
    ];
  }

  /// Students expected today = active enrollments in groups meeting today.
  static TodayAttendance today({
    required DateTime today,
    required Iterable<Group> groups,
    required Iterable<Enrollment> enrollments,
    required Iterable<Attendance> attendance,
  }) {
    final day = AppDates.dateOnly(today);
    final meetingToday = {
      for (final g in groups)
        if (g.sessions.any((s) => s.weekday == day.weekday)) g.id,
    };
    final expected = enrollments.where((e) => e.active && meetingToday.contains(e.groupId)).length;
    final attended = attendance
        .where((a) => AppDates.dateOnly(a.date) == day && _attended(a))
        .map((a) => a.studentId)
        .toSet()
        .length;
    return TodayAttendance(attended: attended, expected: expected);
  }

  static List<Billing> billing({
    required String month,
    required DateTime today,
    required Iterable<Enrollment> enrollments,
    required Iterable<Group> groups,
    required Iterable<Grade> grades,
    required Iterable<Payment> payments,
  }) {
    final groupById = {for (final g in groups) g.id: g};
    final gradeById = {for (final g in grades) g.id: g};
    final result = <Billing>[];
    for (final e in enrollments.where((e) => e.active)) {
      final group = groupById[e.groupId];
      final grade = group == null ? null : gradeById[group.gradeId];
      if (group == null || grade == null) continue;
      final price = PricingService.monthlyPrice(enrollment: e, group: group, grade: grade);
      result.add(
        Billing(
          enrollment: e,
          group: group,
          grade: grade,
          price: price,
          paid: PaymentStatusService.paidAmount(payments, e.studentId, month),
          status: PaymentStatusService.statusFor(
            enrollment: e,
            grade: grade,
            price: price,
            month: month,
            payments: payments,
            today: today,
          ),
        ),
      );
    }
    return result;
  }

  static Map<PaymentStatus, int> countByStatus(Iterable<Billing> billing) => {
    for (final s in PaymentStatus.values) s: billing.where((b) => b.status == s).length,
  };
}
