import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teacher_demo/data/models/models.dart';
import 'package:teacher_demo/services/payment_status_service.dart';
import 'package:teacher_demo/services/pricing_service.dart';

const _grade = Grade(
  id: 'g',
  tenantId: 't',
  name: 'تالتة ثانوي',
  publicPrice: 300,
  dueDay: 5,
  graceDays: 5,
  defaultCapacity: 30,
);

const _public = Group(
  id: 'pub',
  tenantId: 't',
  gradeId: 'g',
  number: 1,
  type: GroupType.public,
  capacity: 30,
  sessions: [],
);

const _private = Group(
  id: 'priv',
  tenantId: 't',
  gradeId: 'g',
  number: 2,
  type: GroupType.private,
  capacity: 5,
  price: 800,
  address: 'x',
  sessions: [],
);

Enrollment _enrollment({bool exempt = false, int discount = 0}) => Enrollment(
  id: 'e',
  tenantId: 't',
  studentId: 's',
  groupId: 'pub',
  joinedAt: DateTime(2026),
  isExempt: exempt,
  discountPercent: discount,
);

Payment _payment(double amount, {String month = '2026-09'}) => Payment(
  id: 'p$amount$month',
  tenantId: 't',
  studentId: 's',
  month: month,
  amount: amount,
  method: PaymentMethod.cash,
  recordedBy: 'a',
  createdAt: DateTime(2026, 9, 3),
);

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('PricingService (rule 1)', () {
    test('public group uses the grade price', () {
      expect(
        PricingService.monthlyPrice(enrollment: _enrollment(), group: _public, grade: _grade),
        300,
      );
    });

    test('private group uses its own price', () {
      expect(
        PricingService.monthlyPrice(enrollment: _enrollment(), group: _private, grade: _grade),
        800,
      );
    });

    test('discount applies to the base price and rounds', () {
      expect(
        PricingService.monthlyPrice(
          enrollment: _enrollment(discount: 25),
          group: _public,
          grade: _grade,
        ),
        225,
      );
      expect(
        PricingService.monthlyPrice(
          enrollment: _enrollment(discount: 15),
          group: _private,
          grade: _grade,
        ),
        680,
      );
    });

    test('exempt students pay nothing even with a discount', () {
      expect(
        PricingService.monthlyPrice(
          enrollment: _enrollment(exempt: true, discount: 20),
          group: _private,
          grade: _grade,
        ),
        0,
      );
    });
  });

  group('PaymentStatusService (rule 2)', () {
    PaymentStatus status(
      DateTime today, {
      List<Payment> payments = const [],
      bool exempt = false,
      double price = 300,
    }) => PaymentStatusService.statusFor(
      enrollment: _enrollment(exempt: exempt),
      grade: _grade,
      price: price,
      month: '2026-09',
      payments: payments,
      today: today,
    );

    test('grace deadline is dueDay + graceDays of the month', () {
      expect(PaymentStatusService.graceDeadline(_grade, '2026-09'), DateTime(2026, 9, 10));
    });

    test('unpaid is due up to and including the grace deadline', () {
      expect(status(DateTime(2026, 9, 1)), PaymentStatus.due);
      expect(status(DateTime(2026, 9, 10, 23, 59)), PaymentStatus.due);
    });

    test('unpaid becomes overdue the day after the grace deadline', () {
      expect(status(DateTime(2026, 9, 11)), PaymentStatus.overdue);
      expect(status(DateTime(2026, 11, 1)), PaymentStatus.overdue);
    });

    test('paid when payments for that month cover the price', () {
      expect(status(DateTime(2026, 9, 20), payments: [_payment(300)]), PaymentStatus.paid);
      expect(
        status(DateTime(2026, 9, 20), payments: [_payment(100), _payment(200)]),
        PaymentStatus.paid,
      );
    });

    test('partial or other-month payments do not count as paid', () {
      expect(status(DateTime(2026, 9, 20), payments: [_payment(150)]), PaymentStatus.overdue);
      expect(
        status(DateTime(2026, 9, 20), payments: [_payment(300, month: '2026-08')]),
        PaymentStatus.overdue,
      );
    });

    test('exempt wins over everything', () {
      expect(status(DateTime(2026, 9, 20), exempt: true), PaymentStatus.exempt);
      expect(status(DateTime(2026, 9, 20), price: 0), PaymentStatus.exempt);
    });

    test('overdue reminders go to the student and each parent with stable ids', () {
      final notifications = PaymentStatusService.overdueNotifications(
        tenantId: 't',
        studentId: 's',
        studentName: 'مريم',
        month: '2026-09',
        amountDue: 300,
        parentIds: ['p1', 'p2'],
        now: DateTime(2026, 9, 27),
      );
      expect(notifications.map((n) => n.userId), ['s', 'p1', 'p2']);
      expect(notifications.every((n) => n.type == NotificationType.payment), isTrue);
      expect(notifications[1].body, contains('مريم'));
      expect(notifications[1].body, contains('300 ج.م'));

      final again = PaymentStatusService.overdueNotifications(
        tenantId: 't',
        studentId: 's',
        studentName: 'مريم',
        month: '2026-09',
        amountDue: 300,
        parentIds: ['p1', 'p2'],
        now: DateTime(2026, 9, 28),
      );
      expect(again.map((n) => n.id), notifications.map((n) => n.id));
    });
  });
}
