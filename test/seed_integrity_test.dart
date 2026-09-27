import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_demo/core/constants/demo_accounts.dart';
import 'package:teacher_demo/core/utils/date_utils.dart';
import 'package:teacher_demo/data/mock/seed_data.dart';
import 'package:teacher_demo/data/mock/seed_generator.dart';
import 'package:teacher_demo/data/models/models.dart';

void main() {
  final now = DateTime(2026, 9, 27, 12);
  late SeedData seed;

  const main = SeedGenerator.mainTenantId;
  const second = SeedGenerator.secondTenantId;

  setUpAll(() => seed = SeedGenerator(now: now).generate());

  List<Enrollment> enrollmentsOf(String tenantId) =>
      seed.enrollments.where((e) => e.tenantId == tenantId).toList();

  test('is deterministic for the same date', () {
    final again = SeedGenerator(now: now).generate();
    expect(jsonEncode(again.toJson()), jsonEncode(seed.toJson()));
  });

  test('has two tenants with the expected teachers', () {
    expect(seed.tenants.map((t) => t.id), [main, second]);
    for (final tenant in seed.tenants) {
      final owner = seed.users.singleWhere((u) => u.id == tenant.ownerUserId);
      expect(owner.role, UserRole.teacher);
    }
  });

  test('main tenant matches the demo spec sizes', () {
    expect(seed.grades.where((g) => g.tenantId == main), hasLength(3));
    final groups = seed.groups.where((g) => g.tenantId == main).toList();
    expect(groups, hasLength(8));
    expect(groups.where((g) => g.isPrivate), hasLength(2));
    expect(enrollmentsOf(main), hasLength(SeedGenerator.mainStudentCount));
    expect(
      seed.users.where((u) => u.role == UserRole.parent),
      hasLength(SeedGenerator.parentCount),
    );

    final staff = seed.staff.where((s) => s.tenantId == main).toList();
    expect(staff, hasLength(2));
    expect(staff.where((s) => s.permissions.length == Permission.values.length), hasLength(1));
    expect(staff.where((s) => s.permissions.length < Permission.values.length), hasLength(1));
  });

  test('user phones are unique and demo accounts exist with the demo password', () {
    final phones = seed.users.map((u) => u.phone).toList();
    expect(phones.toSet().length, phones.length);
    for (final account in DemoAccounts.all) {
      final user = seed.users.singleWhere((u) => u.phone == account.phone);
      expect(user.role, account.role);
      expect(user.password, DemoAccounts.password);
    }
  });

  test('every tenant-scoped row points to an existing tenant', () {
    final tenantIds = seed.tenants.map((t) => t.id).toSet();
    final scoped = <String>[
      ...seed.staff.map((r) => r.tenantId),
      ...seed.grades.map((r) => r.tenantId),
      ...seed.groups.map((r) => r.tenantId),
      ...seed.periods.map((r) => r.tenantId),
      ...seed.enrollments.map((r) => r.tenantId),
      ...seed.attendance.map((r) => r.tenantId),
      ...seed.payments.map((r) => r.tenantId),
      ...seed.expenses.map((r) => r.tenantId),
      ...seed.sheets.map((r) => r.tenantId),
      ...seed.sheetSales.map((r) => r.tenantId),
      ...seed.assessments.map((r) => r.tenantId),
      ...seed.assessmentResults.map((r) => r.tenantId),
      ...seed.requests.map((r) => r.tenantId),
      ...seed.complaints.map((r) => r.tenantId),
      ...seed.announcements.map((r) => r.tenantId),
      ...seed.lessons.map((r) => r.tenantId),
    ];
    expect(scoped.where((id) => !tenantIds.contains(id)), isEmpty);
  });

  test('ids are unique per collection', () {
    for (final entry in seed.toJson().entries) {
      final rows = entry.value;
      if (rows.isEmpty || !rows.first.containsKey('id')) continue;
      final ids = rows.map((r) => r['id']).toList();
      expect(ids.toSet().length, ids.length, reason: entry.key);
    }
  });

  test('enrollments reference existing students and groups of the same tenant', () {
    final groups = {for (final g in seed.groups) g.id: g};
    final students = seed.users.where((u) => u.role == UserRole.student).map((u) => u.id).toSet();
    for (final e in seed.enrollments) {
      expect(students, contains(e.studentId));
      expect(groups[e.groupId]?.tenantId, e.tenantId);
    }
  });

  test('group sizes respect capacity and one group is exactly full', () {
    final groups = seed.groups;
    var fullGroups = 0;
    for (final group in groups) {
      final count = seed.enrollments.where((e) => e.groupId == group.id && e.active).length;
      expect(count, lessThanOrEqualTo(group.capacity), reason: group.id);
      if (count == group.capacity) fullGroups++;
    }
    expect(fullGroups, greaterThanOrEqualTo(1));
  });

  test('private groups have a price and address, public groups do not', () {
    for (final g in seed.groups) {
      expect(g.price != null, g.isPrivate, reason: g.id);
      expect(g.address != null, g.isPrivate, reason: g.id);
      expect(g.sessions, isNotEmpty);
    }
  });

  test('every student has a profile with a unique 6-char link code', () {
    final studentIds = seed.users.where((u) => u.role == UserRole.student).map((u) => u.id);
    final profiles = {for (final p in seed.studentProfiles) p.userId: p};
    for (final id in studentIds) {
      expect(profiles[id], isNotNull, reason: id);
    }
    final codes = seed.studentProfiles.map((p) => p.parentLinkCode).toList();
    expect(codes.toSet().length, codes.length);
    expect(codes.every((c) => RegExp(r'^[A-Z0-9]{6}$').hasMatch(c)), isTrue);
  });

  test('demo student studies with both teachers and demo parent has two children', () {
    final student = seed.users.singleWhere((u) => u.phone == DemoAccounts.studentPhone);
    final tenants = seed.enrollments.where((e) => e.studentId == student.id).map((e) => e.tenantId);
    expect(tenants.toSet(), {main, second});

    final parent = seed.users.singleWhere((u) => u.phone == DemoAccounts.parentPhone);
    final children = seed.parentLinks.where((l) => l.parentUserId == parent.id);
    expect(children, hasLength(2));
    expect(children.map((l) => l.studentUserId), contains(student.id));
  });

  test('parent links reference a parent and a student', () {
    final roles = {for (final u in seed.users) u.id: u.role};
    for (final link in seed.parentLinks) {
      expect(roles[link.parentUserId], UserRole.parent);
      expect(roles[link.studentUserId], UserRole.student);
    }
  });

  test('attendance covers ~2 months, all statuses, and only enrolled or makeup students', () {
    final today = AppDates.dateOnly(now);
    final enrolledGroups = <String, Set<String>>{};
    for (final e in seed.enrollments) {
      enrolledGroups.putIfAbsent(e.studentId, () => {}).add(e.groupId);
    }

    expect(seed.attendance, isNotEmpty);
    for (final a in seed.attendance) {
      expect(a.date.isBefore(today), isTrue);
      expect(today.difference(a.date).inDays, lessThanOrEqualTo(60));
      if (!a.isMakeup) expect(enrolledGroups[a.studentId], contains(a.groupId));
      final attended = a.status == AttendanceStatus.present || a.status == AttendanceStatus.late;
      expect(a.scanTime != null, attended);
      expect(a.lateMinutes > 0, a.status == AttendanceStatus.late);
      expect(a.excuseText != null, a.status == AttendanceStatus.absentExcused);
    }
    expect(seed.attendance.map((a) => a.status).toSet(), AttendanceStatus.values.toSet());
    expect(seed.attendance.where((a) => a.isMakeup), isNotEmpty);
  });

  test('late records exceed the threshold, on-time records do not', () {
    const threshold = 10;
    for (final a in seed.attendance.where((a) => a.tenantId == main)) {
      if (a.status == AttendanceStatus.late) expect(a.lateMinutes, greaterThan(threshold));
    }
  });

  test('payments: one exempt student, some unpaid, demo student unpaid this month', () {
    final exempt = enrollmentsOf(main).where((e) => e.isExempt).toList();
    expect(exempt, hasLength(1));
    expect(seed.payments.where((p) => p.studentId == exempt.single.studentId), isEmpty);

    final currentMonth = AppDates.monthKey(now);
    final paidNow = seed.payments
        .where((p) => p.tenantId == main && p.month == currentMonth)
        .map((p) => p.studentId)
        .toSet();
    final payable = enrollmentsOf(main).where((e) => !e.isExempt).length;
    expect(paidNow.length, lessThan(payable));
    expect(paidNow, isNot(contains(SeedGenerator.studentUserId(0))));

    for (final p in seed.payments) {
      expect(p.amount, greaterThan(0));
      expect(p.referenceNumber == null, p.method == PaymentMethod.cash);
    }
  });

  test('sheets: three with sales, one running low on stock', () {
    final sheets = seed.sheets.where((s) => s.tenantId == main).toList();
    expect(sheets, hasLength(3));
    var lowStock = 0;
    for (final sheet in sheets) {
      final sales = seed.sheetSales.where((s) => s.sheetId == sheet.id).toList();
      expect(sales, isNotEmpty);
      final sold = sales.fold<int>(0, (sum, s) => sum + s.qty);
      expect(sold, lessThanOrEqualTo(sheet.printedQty));
      for (final s in sales) {
        expect(s.total, s.qty * sheet.price);
      }
      if (sheet.printedQty - sold < 10) lowStock++;
    }
    expect(lowStock, greaterThanOrEqualTo(1));
  });

  test('assessments have results only for students of their grade', () {
    expect(seed.assessments, hasLength(4));
    final gradeOfGroup = {for (final g in seed.groups) g.id: g.gradeId};
    for (final assessment in seed.assessments) {
      final results = seed.assessmentResults.where((r) => r.assessmentId == assessment.id);
      expect(results, isNotEmpty);
      for (final r in results) {
        final grades = seed.enrollments
            .where((e) => e.studentId == r.studentId && e.tenantId == assessment.tenantId)
            .map((e) => gradeOfGroup[e.groupId]);
        expect(grades, contains(assessment.gradeId));
        if (r.score != null) {
          expect(r.score, inInclusiveRange(0, assessment.maxScore!));
        }
      }
    }
  });

  test('communication and expense counts match the demo spec', () {
    expect(seed.requests, hasLength(5));
    expect(seed.requests.map((r) => r.status).toSet(), RequestStatus.values.toSet());
    expect(seed.complaints, hasLength(3));
    expect(seed.announcements.where((a) => a.tenantId == main), hasLength(4));
    expect(seed.lessons, hasLength(3));

    final expenseMonths = seed.expenses
        .where((e) => e.tenantId == main)
        .map((e) => AppDates.monthKey(e.date));
    expect(expenseMonths.toSet(), hasLength(6));
    expect(seed.expenses.every((e) => !e.date.isAfter(now)), isTrue);
  });

  test('change-group requests target a group of the same grade', () {
    final groups = {for (final g in seed.groups) g.id: g};
    for (final r in seed.requests.where((r) => r.type == RequestType.changeGroup)) {
      final current = seed.enrollments.singleWhere(
        (e) => e.studentId == r.studentId && e.tenantId == r.tenantId,
      );
      expect(groups[r.requestedGroupId]!.gradeId, groups[current.groupId]!.gradeId);
    }
  });
}
