import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_demo/data/mock/seed_data.dart';
import 'package:teacher_demo/data/mock/seed_generator.dart';
import 'package:teacher_demo/data/models/models.dart';

/// Encodes to a JSON string and back, as a real backend round-trip would.
Map<String, dynamic> _wire(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void _roundTrip<T>(List<T> rows, Map<String, dynamic> Function(T) toJson,
    T Function(Map<String, dynamic>) fromJson) {
  expect(rows, isNotEmpty, reason: '$T has no seed rows');
  for (final row in rows) {
    final copy = fromJson(_wire(toJson(row)));
    expect(copy, row);
    expect(copy.hashCode, row.hashCode);
  }
}

void main() {
  late SeedData seed;
  setUpAll(() => seed = SeedGenerator(now: DateTime(2026, 9, 27, 12)).generate());

  test('every model survives a JSON round-trip with equal value and hash', () {
    _roundTrip(seed.tenants, (r) => r.toJson(), Tenant.fromJson);
    _roundTrip(seed.users, (r) => r.toJson(), User.fromJson);
    _roundTrip(seed.staff, (r) => r.toJson(), StaffMember.fromJson);
    _roundTrip(seed.studentProfiles, (r) => r.toJson(), StudentProfile.fromJson);
    _roundTrip(seed.parentLinks, (r) => r.toJson(), ParentLink.fromJson);
    _roundTrip(seed.grades, (r) => r.toJson(), Grade.fromJson);
    _roundTrip(seed.groups, (r) => r.toJson(), Group.fromJson);
    _roundTrip(seed.periods, (r) => r.toJson(), SchedulePeriods.fromJson);
    _roundTrip(seed.enrollments, (r) => r.toJson(), Enrollment.fromJson);
    _roundTrip(seed.attendance, (r) => r.toJson(), Attendance.fromJson);
    _roundTrip(seed.payments, (r) => r.toJson(), Payment.fromJson);
    _roundTrip(seed.expenses, (r) => r.toJson(), Expense.fromJson);
    _roundTrip(seed.sheets, (r) => r.toJson(), Sheet.fromJson);
    _roundTrip(seed.sheetSales, (r) => r.toJson(), SheetSale.fromJson);
    _roundTrip(seed.assessments, (r) => r.toJson(), Assessment.fromJson);
    _roundTrip(seed.assessmentResults, (r) => r.toJson(), AssessmentResult.fromJson);
    _roundTrip(seed.requests, (r) => r.toJson(), Request.fromJson);
    _roundTrip(seed.complaints, (r) => r.toJson(), Complaint.fromJson);
    _roundTrip(seed.announcements, (r) => r.toJson(), Announcement.fromJson);
    _roundTrip(seed.lessons, (r) => r.toJson(), RecordedLesson.fromJson);
    _roundTrip(seed.notifications, (r) => r.toJson(), AppNotification.fromJson);
  });

  test('copyWith changes only the given field', () {
    final grade = seed.grades.first;
    final changed = grade.copyWith(publicPrice: 999);
    expect(changed.publicPrice, 999);
    expect(changed.copyWith(publicPrice: grade.publicPrice), grade);
    expect(changed, isNot(grade));
  });

  test('set-valued fields compare regardless of order', () {
    const a = StaffMember(
      id: 's',
      tenantId: 't',
      userId: 'u',
      type: StaffType.assistant,
      permissions: {Permission.attendance, Permission.payments},
    );
    final b = a.copyWith(permissions: {Permission.payments, Permission.attendance});
    expect(b, a);
    expect(b.hashCode, a.hashCode);
  });

  test('ClockTime parses, formats and compares', () {
    final t = ClockTime.parse('07:05');
    expect(t.toJson(), '07:05');
    expect(t.addMinutes(70), const ClockTime(8, 15));
    expect(const ClockTime(9, 0).compareTo(const ClockTime(8, 59)), greaterThan(0));
  });
}
