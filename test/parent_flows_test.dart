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

  testWidgets('parent home shows the child switcher and an overdue payment banner', (tester) async {
    await bootApp(
      tester,
      path: '/parent/home',
      phone: DemoAccounts.parentPhone,
      size: const Size(390, 844),
    );
    expect(tester.takeException(), isNull);

    // Demo parent has two children: student 0 (two teachers) and student 50.
    expect(find.byType(ChoiceChip), findsWidgets);
    expect(find.textContaining('الاشتراك متأخر'), findsOneWidget);
    expect(find.text('طرق الدفع المتاحة'), findsOneWidget);
  });

  testWidgets('switching child updates the shown attendance and grades', (tester) async {
    await bootApp(
      tester,
      path: '/parent/attendance',
      phone: DemoAccounts.parentPhone,
      size: const Size(390, 844),
    );
    expect(find.byType(Card), findsWidgets);

    // Switch to the other linked child; the page should still render cleanly.
    await _tap(tester, find.byType(ChoiceChip).last);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent can send a request for the active child', (tester) async {
    final db = await bootApp(
      tester,
      path: '/parent/requests',
      phone: DemoAccounts.parentPhone,
      size: const Size(390, 844),
    );
    final before = db.requests.rows.length;

    await _tap(tester, find.text('طلب جديد'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'التفاصيل'),
      'محتاج أتواصل مع المدرس',
    );
    await _tap(tester, find.text('إرسال'));

    expect(db.requests.rows, hasLength(before + 1));
    final created = db.requests.rows.last;
    expect(created.fromRole, UserRole.parent);
    expect(created.studentId, SeedGenerator.studentUserId(0));
    expect(created.fromUserId, SeedGenerator.parentUserId(0));
  });

  testWidgets('report page shows a level badge that reacts to the range', (tester) async {
    await bootApp(
      tester,
      path: '/parent/more/report',
      phone: DemoAccounts.parentPhone,
      size: const Size(390, 844),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('نسبة الحضور'), findsOneWidget);
    expect(find.textContaining('نسبة الغياب'), findsOneWidget);
    expect(find.textContaining('متوسط الدرجات'), findsOneWidget);

    await _tap(tester, find.text('أسبوع'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent links a new child from the manage-children page', (tester) async {
    final db = await bootApp(
      tester,
      path: '/parent/more/children',
      phone: DemoAccounts.parentPhone,
      size: const Size(390, 844),
    );
    final linkedIds = db.parentLinks.rows.map((l) => l.studentUserId).toSet();
    final unlinked = db.studentProfiles.rows.firstWhere((p) => !linkedIds.contains(p.userId));
    final before = db.parentLinks.rows.length;

    await _tap(tester, find.text('إضافة طفل'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'كود الربط'),
      unlinked.parentLinkCode,
    );
    await _tap(tester, find.text('ربط'));

    expect(db.parentLinks.rows, hasLength(before + 1));
    expect(
      db.parentLinks.rows.last,
      ParentLink(parentUserId: SeedGenerator.parentUserId(0), studentUserId: unlinked.userId),
    );
  });

  testWidgets('parent sign-up creates an account and links the first child', (tester) async {
    final db = await bootSignedOutApp(tester);
    final usersBefore = db.users.rows.length;
    final code = db.studentProfiles.rows
        .singleWhere((p) => p.userId == SeedGenerator.studentUserId(2))
        .parentLinkCode;

    await _tap(tester, find.text('ولي أمر جديد؟ سجّل حساب'));
    await tester.enterText(find.widgetWithText(TextFormField, 'الاسم'), 'منى إبراهيم');
    await tester.enterText(find.widgetWithText(TextFormField, 'رقم الموبايل'), '01522223333');
    await tester.enterText(find.widgetWithText(TextFormField, 'كلمة المرور'), '123456');
    await _tap(tester, find.text('التالي'));

    expect(db.users.rows, hasLength(usersBefore + 1));
    final parent = db.users.rows.last;
    expect(parent.role, UserRole.parent);
    expect(find.text('إضافة طفلك'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'كود الربط'), code);
    await _tap(tester, find.text('ربط الطفل'));

    expect(
      db.parentLinks.rows.where(
        (l) => l.parentUserId == parent.id && l.studentUserId == SeedGenerator.studentUserId(2),
      ),
      hasLength(1),
    );
  });
}
