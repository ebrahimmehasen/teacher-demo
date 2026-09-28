import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teacher_demo/data/mock/seed_generator.dart';
import 'package:teacher_demo/data/models/models.dart';

import 'helpers/app_harness.dart';

/// Taps the first on-screen match (the Stepper keeps hidden copies of other steps' controls).
Future<void> _tap(WidgetTester tester, Finder finder) async {
  var target = finder.hitTestable();
  if (target.evaluate().isEmpty) {
    await tester.ensureVisible(finder.first);
    await tester.pump();
    target = finder.hitTestable();
  }
  await tester.tap(target.first);
  await settle(tester);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await loadAppFonts();
  });

  testWidgets('students table scrolls horizontally on tablet instead of overflowing', (
    tester,
  ) async {
    await bootApp(tester, path: '/teacher/students', size: const Size(768, 1024));
    expect(tester.takeException(), isNull);
    expect(find.byType(DataTable), findsOneWidget);
  });

  testWidgets('teacher adds a public group through the stepper', (tester) async {
    final db = await bootApp(tester, path: '/teacher/schedule');
    final before = db.groups.rows.length;

    await _tap(tester, find.widgetWithText(FilledButton, 'إضافة مجموعة'));
    await _tap(tester, find.byType(DropdownButtonFormField<String>));
    await _tap(tester, find.text('أولى ثانوي').last);
    await _tap(tester, find.text('التالي'));
    await _tap(tester, find.text('التالي'));
    await _tap(tester, find.text('التالي'));
    await _tap(tester, find.widgetWithText(FilterChip, 'الجمعة'));
    await _tap(tester, find.text('حفظ المجموعة'));

    expect(tester.takeException(), isNull);
    expect(db.groups.rows, hasLength(before + 1));
    final added = db.groups.rows.last;
    expect(added.gradeId, 'g-a-1');
    expect(added.number, 4);
    expect(added.type, GroupType.public);
    expect(added.capacity, 30);
    expect(added.sessions.single.weekday, DateTime.friday);
    expect(find.text('تمت إضافة المجموعة'), findsOneWidget);
  });

  testWidgets('stepper blocks a schedule conflict', (tester) async {
    final db = await bootApp(tester, path: '/teacher/schedule');
    final before = db.groups.rows.length;

    await _tap(tester, find.widgetWithText(FilledButton, 'إضافة مجموعة'));
    await _tap(tester, find.byType(DropdownButtonFormField<String>));
    await _tap(tester, find.text('أولى ثانوي').last);
    await _tap(tester, find.text('التالي'));
    await _tap(tester, find.text('التالي'));
    await _tap(tester, find.text('التالي'));
    // Saturday period 1 at 9:00 is taken by "أولى ثانوي – المجموعة الأولى".
    await _tap(tester, find.widgetWithText(FilterChip, 'السبت'));
    await _tap(tester, find.text('حفظ المجموعة'));

    expect(find.textContaining('تعارض في المواعيد').hitTestable(), findsOneWidget);
    expect(db.groups.rows, hasLength(before));
  });

  testWidgets('moving a student into a full group shows "المجموعة مكتملة"', (tester) async {
    final db = await bootApp(tester, path: '/teacher/students');
    final student = db.users.rows.singleWhere((u) => u.id == SeedGenerator.studentUserId(0));
    final before = db.enrollments.rows.singleWhere(
      (e) => e.studentId == student.id && e.tenantId == SeedGenerator.mainTenantId,
    );

    await _tap(tester, find.text(student.name));
    await _tap(tester, find.text('نقل مجموعة'));
    await _tap(tester, find.byType(DropdownButtonFormField<Group>));
    await _tap(tester, find.textContaining('المجموعة الثالثة (5/5)').last);
    await _tap(tester, find.widgetWithText(FilledButton, 'نقل'));

    expect(find.text('المجموعة مكتملة'), findsOneWidget);
    final after = db.enrollments.rows.singleWhere((e) => e.id == before.id);
    expect(after.groupId, before.groupId);
  });

  testWidgets('bulk exempt updates the enrollment and its payment status', (tester) async {
    final db = await bootApp(tester, path: '/teacher/students');
    final student = db.users.rows.singleWhere((u) => u.id == SeedGenerator.studentUserId(0));

    await _tap(tester, find.text(student.name));
    await _tap(tester, find.text('إعفاء'));

    final enrollment = db.enrollments.rows.singleWhere(
      (e) => e.studentId == student.id && e.tenantId == SeedGenerator.mainTenantId,
    );
    expect(enrollment.isExempt, isTrue);
    expect(find.text('تم إعفاء الطلاب المحددين'), findsOneWidget);
  });

  testWidgets('teacher adds a grade from settings', (tester) async {
    final db = await bootApp(tester, path: '/teacher/settings');

    await _tap(tester, find.text('إضافة صف'));
    await tester.enterText(find.widgetWithText(TextFormField, 'اسم الصف'), 'الصف الثالث الإعدادي');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'سعر الشهر (المجموعات العامة)'),
      '200',
    );
    await _tap(tester, find.widgetWithText(FilledButton, 'حفظ'));

    final grade = db.grades.rows.singleWhere((g) => g.name == 'الصف الثالث الإعدادي');
    expect(grade.tenantId, SeedGenerator.mainTenantId);
    expect(grade.publicPrice, 200);
    expect(grade.dueDay, 5);
    expect(find.text('الصف الثالث الإعدادي'), findsOneWidget);
  });
}
