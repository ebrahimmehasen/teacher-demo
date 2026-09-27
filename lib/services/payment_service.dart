import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/labels.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/money.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';
import 'notification_service.dart';

class PaymentService {
  PaymentService(this._payments, this._notifier);

  final PaymentRepository _payments;
  final ActivityNotifier _notifier;
  static const _uuid = Uuid();

  /// E-wallets and transfers need a reference number to be traceable.
  static bool requiresReference(PaymentMethod method) =>
      method != PaymentMethod.cash && method != PaymentMethod.other;

  /// Months offered in the payment form: 5 back, the current one, 1 ahead.
  static List<String> selectableMonths(DateTime today) => [
    for (var offset = 1; offset >= -5; offset--)
      AppDates.monthKey(AppDates.addMonths(today, offset)),
  ];

  Future<Payment> record({
    required String tenantId,
    required User student,
    required String month,
    required double amount,
    required PaymentMethod method,
    required String recordedBy,
    required DateTime now,
    String? referenceNumber,
    String? note,
  }) async {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount', 'must be positive');
    if (requiresReference(method) && (referenceNumber == null || referenceNumber.trim().isEmpty)) {
      throw ArgumentError('Reference number required for ${method.name}');
    }
    final payment = Payment(
      id: _uuid.v4(),
      tenantId: tenantId,
      studentId: student.id,
      month: month,
      amount: amount,
      method: method,
      referenceNumber: requiresReference(method) ? referenceNumber!.trim() : null,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      recordedBy: recordedBy,
      createdAt: now,
    );
    await _payments.add(payment);

    final monthName = AppDates.monthYear(AppDates.parseMonthKey(month));
    final value = Money.format(amount);
    await _notifier.notifyStudentCircle(
      tenantId: tenantId,
      studentId: student.id,
      type: NotificationType.payment,
      now: now,
      message: EventMessage(
        title: 'تم استلام دفعة',
        forStudent: 'تم استلام $value اشتراك شهر $monthName. شكراً لك.',
        forParent: 'تم استلام $value اشتراك شهر $monthName للطالب ${student.name}.',
        forTeacher: '${student.name} دفع $value (${method.label}) عن شهر $monthName.',
        teacherLink: '/teacher/students',
      ),
    );
    return payment;
  }
}

final paymentServiceProvider = Provider(
  (ref) =>
      PaymentService(ref.watch(paymentRepositoryProvider), ref.watch(activityNotifierProvider)),
);
