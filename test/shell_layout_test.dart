import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_demo/core/router/role_destinations.dart';
import 'package:teacher_demo/core/theme/app_theme.dart';
import 'package:teacher_demo/features/shared/shell/adaptive_shell.dart';
import 'package:teacher_demo/features/shared/shell/bottom_nav_shell.dart';
import 'package:teacher_demo/features/shared/shell/shell_header.dart';

/// Loads the bundled Cairo font so text widths match the real app, not the test font.
Future<void> _loadCairo() async {
  final loader = FontLoader(AppTheme.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/Cairo-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _pump(WidgetTester tester, Size size, Widget shell) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Directionality(textDirection: TextDirection.rtl, child: shell),
    ),
  ));
  await tester.pumpAndSettle();
}

const _teacherShell = AdaptiveShell(
  destinations: RoleDestinations.teacher,
  location: '/teacher/dashboard',
  header: ShellHeader(title: 'أ. أحمد سامي', subtitle: 'مادة فيزياء'),
  child: SizedBox.expand(),
);

void main() {
  setUpAll(_loadCairo);

  testWidgets('wide screens show a navigation rail with the tenant header', (tester) async {
    await _pump(tester, const Size(1024, 768), _teacherShell);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(NavigationRail)).width, greaterThan(200));
    expect(find.text('أ. أحمد سامي'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
  });

  testWidgets('short wide screens scroll the rail instead of overflowing', (tester) async {
    await _pump(tester, const Size(1024, 500), _teacherShell);
    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets('phones use a drawer instead of a rail', (tester) async {
    await _pump(tester, const Size(390, 844), _teacherShell);
    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('أ. أحمد سامي'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
  });

  testWidgets('student shell shows the five bottom tabs', (tester) async {
    await _pump(
      tester,
      const Size(375, 812),
      const BottomNavShell(
        destinations: RoleDestinations.student,
        location: '/student/qr',
        title: ShellHeader(title: 'محمد شريف بدوي', subtitle: 'أ. أحمد سامي – فيزياء'),
        child: SizedBox.expand(),
      ),
    );
    expect(tester.takeException(), isNull);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations, hasLength(5));
    expect(bar.selectedIndex, 1);
  });
}
