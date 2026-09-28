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

  testWidgets('student QR page shows a rotating token and a countdown', (tester) async {
    await bootApp(
      tester,
      path: '/student/qr',
      phone: DemoAccounts.studentPhone,
      size: const Size(390, 844),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('يتجدد الكود تلقائياً'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Ticks down without throwing (Timer.periodic + screen protection no-op on desktop).
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('student schedule lists their own group sessions', (tester) async {
    await bootApp(
      tester,
      path: '/student/schedule',
      phone: DemoAccounts.studentPhone,
      size: const Size(390, 844),
    );
    expect(tester.takeException(), isNull);
    // grp-a-6 meets Saturday and Tuesday.
    expect(find.text('السبت'), findsOneWidget);
    expect(find.text('الثلاثاء'), findsOneWidget);
    expect(find.textContaining('تالتة ثانوي'), findsWidgets);
  });

  testWidgets('student attendance page shows their recorded history', (tester) async {
    await bootApp(
      tester,
      path: '/student/more/attendance',
      phone: DemoAccounts.studentPhone,
      size: const Size(390, 844),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(Card), findsWidgets);
    expect(find.text('لا يوجد سجل حضور بعد'), findsNothing);
  });

  testWidgets('student can create an absence request and see it listed', (tester) async {
    final db = await bootApp(
      tester,
      path: '/student/requests',
      phone: DemoAccounts.studentPhone,
      size: const Size(390, 844),
    );
    final before = db.requests.rows.length;

    await _tap(tester, find.text('طلب جديد'));
    await tester.enterText(find.widgetWithText(TextFormField, 'التفاصيل'), 'عندي ظرف طارئ');
    await _tap(tester, find.text('إرسال'));

    expect(db.requests.rows, hasLength(before + 1));
    final created = db.requests.rows.last;
    expect(created.studentId, SeedGenerator.studentUserId(0));
    expect(created.fromRole, UserRole.student);
    expect(created.type, RequestType.absence);
    expect(find.text('تم إرسال الطلب'), findsOneWidget);
    expect(find.text('عندي ظرف طارئ'), findsOneWidget);
  });

  testWidgets('student more menu opens profile with the parent link code', (tester) async {
    final db = await bootApp(
      tester,
      path: '/student/more',
      phone: DemoAccounts.studentPhone,
      size: const Size(390, 844),
    );
    await _tap(tester, find.text('الملف الشخصي'));

    final code = db.studentProfiles.rows
        .singleWhere((p) => p.userId == SeedGenerator.studentUserId(0))
        .parentLinkCode;
    expect(find.text(code), findsOneWidget);
  });

  testWidgets('the enrollment switcher appears only for a student with two tenants', (
    tester,
  ) async {
    // Demo student (index 0) studies with both teachers.
    await bootApp(
      tester,
      path: '/student/home',
      phone: DemoAccounts.studentPhone,
      size: const Size(390, 844),
    );
    expect(find.textContaining('أ. منى عادل'), findsOneWidget);

    await _tap(tester, find.textContaining('أ. منى عادل'));
    expect(find.textContaining('كيمياء'), findsWidgets);
  });
}
