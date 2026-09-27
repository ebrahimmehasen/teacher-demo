import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_demo/data/models/models.dart';
import 'package:teacher_demo/services/accounts_service.dart';
import 'package:teacher_demo/services/dashboard_service.dart';
import 'package:teacher_demo/services/group_service.dart';

Group _group(
  String id, {
  int capacity = 3,
  int number = 1,
  List<GroupSession> sessions = const [],
}) => Group(
  id: id,
  tenantId: 't',
  gradeId: 'g',
  number: number,
  type: GroupType.public,
  capacity: capacity,
  sessions: sessions,
);

Enrollment _enrollment(String id, String groupId, {bool active = true}) => Enrollment(
  id: id,
  tenantId: 't',
  studentId: 's-$id',
  groupId: groupId,
  joinedAt: DateTime(2026),
  active: active,
);

GroupSession _session(int weekday, int startHour, {int minutes = 90}) => GroupSession(
  weekday: weekday,
  periodIndex: 0,
  startTime: ClockTime(startHour, 0),
  endTime: ClockTime(startHour, 0).addMinutes(minutes),
);

void main() {
  group('GroupService capacity (rule 4)', () {
    final full = _group('full', capacity: 2);
    final roomy = _group('roomy', capacity: 3);
    final enrollments = [
      _enrollment('1', 'full'),
      _enrollment('2', 'full'),
      _enrollment('3', 'roomy'),
      _enrollment('4', 'roomy', active: false),
    ];

    test('counts only active enrollments', () {
      expect(GroupService.enrolledCount('roomy', enrollments), 1);
      expect(GroupService.hasRoom(roomy, enrollments, adding: 2), isTrue);
      expect(GroupService.hasRoom(roomy, enrollments, adding: 3), isFalse);
    });

    test('moving into a full group throws CapacityException', () {
      expect(
        () => GroupService.moveTo(full, [enrollments[2]], enrollments),
        throwsA(isA<CapacityException>()),
      );
    });

    test('students already in the target group do not take extra seats', () {
      final moved = GroupService.moveTo(full, [enrollments[0]], enrollments);
      expect(moved, isEmpty);
    });

    test('moving updates the group id of incoming students', () {
      final moved = GroupService.moveTo(roomy, [enrollments[0], enrollments[1]], enrollments);
      expect(moved.map((e) => e.groupId), ['roomy', 'roomy']);
      expect(moved.map((e) => e.id), ['1', '2']);
    });
  });

  group('GroupService schedule', () {
    test('next number follows the highest in the grade', () {
      expect(GroupService.nextNumber('g', [_group('a', number: 1), _group('b', number: 3)]), 4);
      expect(GroupService.nextNumber('other', [_group('a')]), 1);
    });

    test('overlapping sessions on the same day conflict, touching ones do not', () {
      final existing = _group('x', sessions: [_session(DateTime.saturday, 17)]);
      expect(GroupService.conflictingGroups([_session(DateTime.saturday, 18)], [existing]), [
        existing,
      ]);
      expect(
        GroupService.conflictingGroups([_session(DateTime.saturday, 15, minutes: 120)], [existing]),
        isEmpty,
      );
      expect(GroupService.conflictingGroups([_session(DateTime.sunday, 17)], [existing]), isEmpty);
      expect(
        GroupService.conflictingGroups(
          [_session(DateTime.saturday, 17)],
          [existing],
          ignoreGroupId: 'x',
        ),
        isEmpty,
      );
    });

    test('default start reuses the most common time for the period', () {
      final g = _group(
        'x',
        sessions: [
          GroupSession(
            weekday: 6,
            periodIndex: 2,
            startTime: const ClockTime(14, 30),
            endTime: const ClockTime(16, 0),
          ),
        ],
      );
      expect(GroupService.defaultStart(2, [g]), const ClockTime(14, 30));
      expect(GroupService.defaultStart(0, [g]), const ClockTime(9, 0));
      expect(GroupService.defaultStart(10, const []), const ClockTime(21, 0));
    });
  });

  group('AccountsService (rule 11)', () {
    final payments = [
      Payment(
        id: 'p1',
        tenantId: 't',
        studentId: 's',
        month: '2026-09',
        amount: 300,
        method: PaymentMethod.cash,
        recordedBy: 'a',
        createdAt: DateTime(2026, 8, 30),
      ),
    ];
    final sales = [
      SheetSale(
        id: 's1',
        tenantId: 't',
        sheetId: 'x',
        date: DateTime(2026, 9, 12),
        qty: 2,
        total: 100,
        recordedBy: 'a',
      ),
    ];
    final expenses = [
      Expense(
        id: 'e1',
        tenantId: 't',
        title: 'rent',
        category: ExpenseCategory.rent,
        amount: 150,
        date: DateTime(2026, 9, 1),
      ),
    ];

    test('income = payments for the month + sheet sales; net = income − expenses', () {
      final s = AccountsService.summarize(
        '2026-09',
        payments: payments,
        sales: sales,
        expenses: expenses,
      );
      expect(s.paymentsIncome, 300);
      expect(s.sheetsIncome, 100);
      expect(s.income, 400);
      expect(s.expenses, 150);
      expect(s.net, 250);
    });

    test('lastMonths returns oldest first ending with the current month', () {
      final months = AccountsService.lastMonths(
        DateTime(2026, 9, 27),
        3,
        payments: payments,
        sales: sales,
        expenses: expenses,
      );
      expect(months.map((m) => m.month), ['2026-07', '2026-08', '2026-09']);
      expect(months.first.income, 0);
    });
  });

  group('DashboardService', () {
    Attendance record(DateTime day, String student, AttendanceStatus status) => Attendance(
      id: '$day$student',
      tenantId: 't',
      studentId: student,
      groupId: 'a',
      date: day,
      status: status,
      method: AttendanceMethod.manual,
      recordedBy: 'x',
    );

    test('daily attendance counts present and late as attended', () {
      final day = DateTime(2026, 9, 20);
      final days = DashboardService.dailyAttendance(
        [
          record(day, '1', AttendanceStatus.present),
          record(day, '2', AttendanceStatus.late),
          record(day, '3', AttendanceStatus.absentExcused),
          record(day, '4', AttendanceStatus.absent),
          record(DateTime(2026, 7, 1), '1', AttendanceStatus.present),
        ],
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 27),
      );
      expect(days, hasLength(1));
      expect(days.single.attended, 2);
      expect(days.single.total, 4);
      expect(days.single.rate, 0.5);
    });

    test("today's expected students come from groups meeting today", () {
      final saturday = DateTime(2026, 9, 26);
      final result = DashboardService.today(
        today: saturday,
        groups: [
          _group('a', sessions: [_session(DateTime.saturday, 17)]),
          _group('b', sessions: [_session(DateTime.sunday, 17)]),
        ],
        enrollments: [_enrollment('1', 'a'), _enrollment('2', 'a'), _enrollment('3', 'b')],
        attendance: [record(saturday, 's-1', AttendanceStatus.late)],
      );
      expect(result.expected, 2);
      expect(result.attended, 1);
    });
  });
}
