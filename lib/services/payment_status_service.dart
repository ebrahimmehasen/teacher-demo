import '../core/utils/date_utils.dart';
import '../core/utils/money.dart';
import '../data/models/models.dart';

enum PaymentStatus { paid, due, overdue, exempt }

/// Rule 2: paid | due (today ≤ dueDay + graceDays) | overdue (after grace) | exempt.
abstract final class PaymentStatusService {
  /// Last day the month can be paid without being overdue.
  static DateTime graceDeadline(Grade grade, String month) {
    final start = AppDates.parseMonthKey(month);
    return DateTime(start.year, start.month, grade.dueDay + grade.graceDays);
  }

  static PaymentStatus statusFor({
    required Enrollment enrollment,
    required Grade grade,
    required double price,
    required String month,
    required Iterable<Payment> payments,
    required DateTime today,
  }) {
    if (enrollment.isExempt || price <= 0) return PaymentStatus.exempt;

    final paid = payments
        .where((p) => p.studentId == enrollment.studentId && p.month == month)
        .fold<double>(0, (sum, p) => sum + p.amount);
    if (paid >= price) return PaymentStatus.paid;

    return AppDates.dateOnly(today).isAfter(graceDeadline(grade, month))
        ? PaymentStatus.overdue
        : PaymentStatus.due;
  }

  static double paidAmount(Iterable<Payment> payments, String studentId, String month) => payments
      .where((p) => p.studentId == studentId && p.month == month)
      .fold<double>(0, (sum, p) => sum + p.amount);

  /// Deterministic id so each (student, month, recipient) reminder is created once.
  static String overdueNotificationId(
    String tenantId,
    String studentId,
    String month,
    String recipientId,
  ) => 'overdue-$tenantId-$studentId-$month-$recipientId';

  /// Overdue reminders for the student and each linked parent. Callers insert them
  /// with insert-if-absent semantics, so re-running is harmless.
  static List<AppNotification> overdueNotifications({
    required String tenantId,
    required String studentId,
    required String studentName,
    required String month,
    required double amountDue,
    required Iterable<String> parentIds,
    required DateTime now,
  }) {
    final monthName = AppDates.monthYear(AppDates.parseMonthKey(month));
    AppNotification build(String userId, String body, String deepLink) => AppNotification(
      id: overdueNotificationId(tenantId, studentId, month, userId),
      userId: userId,
      tenantId: tenantId,
      title: 'اشتراك متأخر',
      body: body,
      type: NotificationType.payment,
      createdAt: now,
      deepLink: deepLink,
    );

    return [
      build(
        studentId,
        'اشتراك شهر $monthName متأخر (${Money.format(amountDue)}).',
        '/student/home',
      ),
      for (final parentId in parentIds)
        build(
          parentId,
          'اشتراك شهر $monthName لـ $studentName متأخر (${Money.format(amountDue)}).',
          '/parent/home',
        ),
    ];
  }
}
