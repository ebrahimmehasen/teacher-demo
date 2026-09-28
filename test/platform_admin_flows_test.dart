import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teacher_demo/core/constants/demo_accounts.dart';
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

  testWidgets('platform admin sees both demo tenants with student counts', (tester) async {
    await bootApp(tester, path: '/admin/tenants', phone: DemoAccounts.platformAdminPhone);
    expect(tester.takeException(), isNull);

    expect(find.text('أ. أحمد سامي'), findsOneWidget);
    expect(find.text('أ. منى عادل'), findsOneWidget);
    expect(find.textContaining('60 طالب'), findsOneWidget);
  });

  testWidgets('platform admin adds a new teacher', (tester) async {
    final db = await bootApp(
      tester,
      path: '/admin/tenants',
      phone: DemoAccounts.platformAdminPhone,
    );
    final tenantsBefore = db.tenants.rows.length;

    await _tap(tester, find.text('إضافة مدرس'));
    await tester.enterText(find.widgetWithText(TextFormField, 'اسم المدرس'), 'أ. سمير فوزي');
    await tester.enterText(find.widgetWithText(TextFormField, 'المادة'), 'أحياء');
    await tester.enterText(find.widgetWithText(TextFormField, 'رقم الموبايل'), '01288889999');
    await _tap(tester, find.widgetWithText(FilledButton, 'إضافة'));

    expect(db.tenants.rows, hasLength(tenantsBefore + 1));
    expect(find.text('أ. سمير فوزي'), findsOneWidget);
  });

  testWidgets('platform admin deactivates a tenant', (tester) async {
    final db = await bootApp(
      tester,
      path: '/admin/tenants',
      phone: DemoAccounts.platformAdminPhone,
    );
    final tenant = db.tenants.rows.first;
    expect(tenant.subscriptionStatus, SubscriptionStatus.active);

    await _tap(tester, find.byType(Switch).first);
    await _tap(tester, find.widgetWithText(FilledButton, 'إيقاف'));

    expect(
      db.tenants.rows.singleWhere((t) => t.id == tenant.id).subscriptionStatus,
      SubscriptionStatus.expired,
    );
  });
}
