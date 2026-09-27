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

  testWidgets('assistant records a cash payment; the student becomes paid', (tester) async {
    final db = await bootApp(
      tester,
      path: '/assistant/payments',
      phone: DemoAccounts.assistantPhone,
    );
    final student = db.users.rows.singleWhere((u) => u.id == SeedGenerator.studentUserId(0));
    final before = db.payments.rows.length;

    await tester.enterText(find.byType(TextField).first, student.name);
    await settle(tester);
    await _tap(tester, find.widgetWithText(ListTile, student.name));
    expect(find.text('الاشتراك الشهري: 350 ج.م'), findsOneWidget);
    await _tap(tester, find.text('تسجيل الدفع'));

    expect(db.payments.rows, hasLength(before + 1));
    final payment = db.payments.rows.last;
    expect(payment.studentId, student.id);
    expect(payment.amount, 350);
    expect(payment.month, '2026-09');
    expect(payment.method, PaymentMethod.cash);
    expect(find.text('مدفوع').hitTestable(), findsWidgets);
  });

  testWidgets('wallet payment requires a reference number', (tester) async {
    final db = await bootApp(
      tester,
      path: '/assistant/payments',
      phone: DemoAccounts.assistantPhone,
    );
    final student = db.users.rows.singleWhere((u) => u.id == SeedGenerator.studentUserId(0));
    final before = db.payments.rows.length;

    await tester.enterText(find.byType(TextField).first, student.name);
    await settle(tester);
    await _tap(tester, find.widgetWithText(ListTile, student.name));
    await _tap(tester, find.widgetWithText(ChoiceChip, 'فودافون كاش'));
    await _tap(tester, find.text('تسجيل الدفع'));
    expect(find.text('رقم العملية مطلوب'), findsOneWidget);
    expect(db.payments.rows, hasLength(before));

    await tester.enterText(find.widgetWithText(TextFormField, 'رقم العملية / المرجع'), '7788');
    await _tap(tester, find.text('تسجيل الدفع'));
    expect(db.payments.rows.last.referenceNumber, '7788');
  });

  testWidgets('assistant adds a student with a new parent and sees the link code', (tester) async {
    final db = await bootApp(
      tester,
      path: '/assistant/students',
      phone: DemoAccounts.assistantPhone,
    );

    await _tap(tester, find.text('إضافة طالب'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'اسم الطالب رباعي'),
      'ليلى محمود حسن علي',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'موبايل الطالب'), '01211112222');
    await _tap(tester, find.widgetWithText(DropdownButtonFormField<String>, 'الصف'));
    await _tap(tester, find.text('أولى ثانوي').last);
    await _tap(tester, find.widgetWithText(DropdownButtonFormField<String>, 'المجموعة'));
    await _tap(tester, find.textContaining('المجموعة الأولى (').last);
    await tester.enterText(find.widgetWithText(TextFormField, 'موبايل ولي الأمر'), '01511112222');
    await _tap(tester, find.widgetWithText(FilledButton, 'إضافة'));

    expect(find.text('تمت إضافة الطالب'), findsOneWidget);
    final student = db.users.rows.singleWhere((u) => u.phone == '01211112222');
    final code = db.studentProfiles.rows.singleWhere((p) => p.userId == student.id).parentLinkCode;
    expect(find.text(code), findsOneWidget);
    expect(db.users.rows.singleWhere((u) => u.phone == '01511112222').role, UserRole.parent);
  });

  testWidgets('manual attendance saves the chosen statuses', (tester) async {
    final db = await bootApp(
      tester,
      path: '/assistant/manual-attendance',
      phone: DemoAccounts.assistantPhone,
    );
    final before = db.attendance.rows.length;

    await _tap(tester, find.text('الباقي حاضر'));
    await _tap(tester, find.text('حفظ الحضور'));

    final today = DateTime(2026, 9, 27);
    final saved = db.attendance.rows.where((a) => a.date == today).toList();
    expect(saved, isNotEmpty);
    expect(db.attendance.rows.length, before + saved.length);
    expect(saved.every((a) => a.status == AttendanceStatus.present), isTrue);
    expect(saved.every((a) => a.method == AttendanceMethod.manual), isTrue);
  });

  testWidgets('sheet sale computes the total and updates stock', (tester) async {
    final db = await bootApp(tester, path: '/assistant/sheets', phone: DemoAccounts.assistantPhone);
    final before = db.sheetSales.rows.length;

    expect(find.text('متبقي 7 فقط'), findsOneWidget);
    final reviewBook = find.ancestor(
      of: find.text('كتاب المراجعة النهائية – تالتة ثانوي'),
      matching: find.byType(Card),
    );
    await _tap(tester, find.descendant(of: reviewBook, matching: find.text('تسجيل بيع')));
    await _tap(tester, find.byIcon(Icons.add));
    expect(find.text('الإجمالي: 240 ج.م'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'تسجيل'));

    expect(db.sheetSales.rows, hasLength(before + 1));
    expect(db.sheetSales.rows.last.qty, 2);
    expect(find.text('متبقي 5 فقط'), findsOneWidget);
  });

  testWidgets('limited supervisor only sees permitted screens', (tester) async {
    await bootApp(tester, path: '/assistant/home', phone: DemoAccounts.limitedAssistantPhone);

    expect(find.text('مسح QR').hitTestable(), findsWidgets);
    expect(find.text('بيع المذكرات').hitTestable(), findsWidgets);
    expect(find.text('المدفوعات'), findsNothing);
    expect(find.text('رصد الدرجات'), findsNothing);
  });
}
