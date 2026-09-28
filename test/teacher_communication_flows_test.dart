import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teacher_demo/core/constants/demo_accounts.dart';
import 'package:teacher_demo/data/mock/seed_generator.dart';
import 'package:teacher_demo/data/models/models.dart';

import 'helpers/app_harness.dart';

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

  testWidgets('teacher approves a pending request', (tester) async {
    final db = await bootApp(tester, path: '/teacher/requests', phone: DemoAccounts.teacherPhone);
    final pending = db.requests.rows.firstWhere(
      (r) => r.status == RequestStatus.pending && r.type != RequestType.changeGroup,
    );

    await _tap(tester, find.widgetWithText(FilledButton, 'قبول').first);
    await _tap(tester, find.widgetWithText(FilledButton, 'تأكيد'));

    expect(db.requests.rows.singleWhere((r) => r.id == pending.id).status, RequestStatus.approved);
    expect(find.text('تم قبول الطلب'), findsOneWidget);
  });

  testWidgets('teacher sends a warning to a student', (tester) async {
    final db = await bootApp(tester, path: '/teacher/requests', phone: DemoAccounts.teacherPhone);
    final before = db.complaints.rows.length;

    await _tap(tester, find.text('إرسال شكوى / تنبيه'));
    await _tap(tester, find.text('اختر الطالب'));
    await tester.enterText(find.byType(TextField).first, 'آية سامح');
    await settle(tester);
    await _tap(
      tester,
      find.text('آية سامح عبدالله').first.hitTestable().evaluate().isNotEmpty
          ? find.text('آية سامح عبدالله').first
          : find.byType(ListTile).first,
    );
    await _tap(tester, find.text('تنبيه للطالب'));
    await tester.enterText(find.widgetWithText(TextFormField, 'النص'), 'التزم بالهدوء داخل الحصة');
    await _tap(tester, find.text('إرسال'));

    expect(db.complaints.rows, hasLength(before + 1));
    expect(db.complaints.rows.last.kind, ComplaintKind.warning);
    expect(find.text('تم الإرسال'), findsOneWidget);
  });

  testWidgets('teacher publishes an announcement for a grade', (tester) async {
    final db = await bootApp(
      tester,
      path: '/teacher/announcements',
      phone: DemoAccounts.teacherPhone,
    );
    final before = db.announcements.rows.length;
    final notifBefore = db.notifications.rows.length;

    await _tap(tester, find.text('إعلان جديد'));
    await _tap(tester, find.widgetWithText(DropdownButtonFormField<String?>, 'الجهة المستهدفة'));
    await _tap(tester, find.text('أولى ثانوي').last);
    await tester.enterText(find.widgetWithText(TextFormField, 'العنوان'), 'اختبار قصير');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'النص'),
      'غداً اختبار قصير في الباب الأول',
    );
    await _tap(tester, find.text('نشر'));

    expect(db.announcements.rows, hasLength(before + 1));
    expect(db.announcements.rows.last.gradeId, 'g-a-1');
    expect(db.notifications.rows.length, greaterThan(notifBefore));
    expect(find.text('تم نشر الإعلان'), findsOneWidget);
  });

  testWidgets('teacher adds a sheet and it appears in the table', (tester) async {
    final db = await bootApp(tester, path: '/teacher/sheets', phone: DemoAccounts.teacherPhone);
    final before = db.sheets.rows.length;

    await _tap(tester, find.text('إضافة مذكرة'));
    await tester.enterText(find.widgetWithText(TextFormField, 'العنوان'), 'مذكرة تجريبية');
    await _tap(tester, find.widgetWithText(DropdownButtonFormField<String>, 'الصف'));
    await _tap(tester, find.text('أولى ثانوي').last);
    await tester.enterText(find.widgetWithText(TextFormField, 'السعر'), '30');
    await tester.enterText(find.widgetWithText(TextFormField, 'العدد المطبوع'), '50');
    await _tap(tester, find.widgetWithText(FilledButton, 'إضافة'));

    expect(db.sheets.rows, hasLength(before + 1));
    expect(find.text('مذكرة تجريبية'), findsOneWidget);
  });

  testWidgets('teacher adds a recorded lesson', (tester) async {
    final db = await bootApp(tester, path: '/teacher/lessons', phone: DemoAccounts.teacherPhone);
    final before = db.lessons.rows.length;

    await _tap(tester, find.text('إضافة حصة'));
    await tester.enterText(find.widgetWithText(TextFormField, 'عنوان الحصة'), 'مراجعة نهائية');
    await _tap(tester, find.widgetWithText(DropdownButtonFormField<String>, 'الصف'));
    await _tap(tester, find.text('أولى ثانوي').last);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'رابط Drive'),
      'https://drive.google.com/x',
    );
    await _tap(tester, find.widgetWithText(FilledButton, 'إضافة'));

    expect(db.lessons.rows, hasLength(before + 1));
    expect(find.text('مراجعة نهائية'), findsOneWidget);
  });

  testWidgets('teacher creates an assessment from the grades page', (tester) async {
    final db = await bootApp(tester, path: '/teacher/grades', phone: DemoAccounts.teacherPhone);
    final before = db.assessments.rows.length;

    await _tap(tester, find.text('واجب / امتحان جديد'));
    await tester.enterText(find.widgetWithText(TextFormField, 'العنوان'), 'واجب المتجهات');
    await _tap(tester, find.widgetWithText(DropdownButtonFormField<String>, 'الصف'));
    await _tap(tester, find.text('أولى ثانوي').last);
    await _tap(tester, find.widgetWithText(FilledButton, 'إضافة'));

    expect(db.assessments.rows, hasLength(before + 1));
    expect(db.assessments.rows.last.title, 'واجب المتجهات');
  });

  testWidgets('teacher adds a staff member with permissions', (tester) async {
    final db = await bootApp(tester, path: '/teacher/staff', phone: DemoAccounts.teacherPhone);
    final before = db.staff.rows.length;

    await _tap(tester, find.text('إضافة مساعد'));
    await tester.enterText(find.widgetWithText(TextFormField, 'الاسم'), 'مساعد تجريبي');
    await tester.enterText(find.widgetWithText(TextFormField, 'رقم الموبايل'), '01166667777');
    await _tap(tester, find.widgetWithText(FilledButton, 'إضافة'));

    expect(db.staff.rows, hasLength(before + 1));
    final added = db.staff.rows.last;
    expect(added.permissions, Permission.values.toSet());
    expect(find.text('مساعد تجريبي'), findsOneWidget);
  });

  testWidgets('teacher records an expense and sees it in the monthly total', (tester) async {
    final db = await bootApp(tester, path: '/teacher/accounts', phone: DemoAccounts.teacherPhone);
    final before = db.expenses.rows.length;

    await _tap(tester, find.text('مصروف جديد'));
    await tester.enterText(find.widgetWithText(TextFormField, 'البند'), 'صيانة مكيفات');
    await tester.enterText(find.widgetWithText(TextFormField, 'المبلغ'), '500');
    await _tap(tester, find.widgetWithText(FilledButton, 'إضافة'));

    expect(db.expenses.rows, hasLength(before + 1));
    expect(find.text('صيانة مكيفات'), findsOneWidget);
  });

  testWidgets('student detail sheet opens from the students page', (tester) async {
    await bootApp(tester, path: '/teacher/students', phone: DemoAccounts.teacherPhone);

    await _tap(tester, find.byIcon(Icons.info_outline).first);

    // Section headers below the fold are still in the tree, just offstage
    // inside the DraggableScrollableSheet's list until scrolled into view.
    expect(find.text('الحضور', skipOffstage: false), findsWidgets);
    expect(find.text('المدفوعات', skipOffstage: false), findsWidgets);
  });

  testWidgets('notification bell opens the panel and marks items read', (tester) async {
    final db = await bootApp(tester, path: '/teacher/dashboard', phone: DemoAccounts.teacherPhone);
    final userId = SeedGenerator.teacherUserId;
    final unreadBefore = db.notifications.rows.where((n) => n.userId == userId && !n.read).length;
    expect(unreadBefore, greaterThan(0));

    await _tap(tester, find.byIcon(Icons.notifications_outlined));
    expect(find.text('الإشعارات'), findsOneWidget);

    await _tap(tester, find.text('تحديد الكل كمقروء'));
    expect(db.notifications.rows.where((n) => n.userId == userId && !n.read), isEmpty);
  });
}
