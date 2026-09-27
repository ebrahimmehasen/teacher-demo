import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_demo/app.dart';
import 'package:teacher_demo/core/constants/demo_accounts.dart';
import 'package:teacher_demo/core/router/app_router.dart';
import 'package:teacher_demo/core/theme/app_theme.dart';
import 'package:teacher_demo/data/mock/mock_database.dart';
import 'package:teacher_demo/data/mock/seed_generator.dart';
import 'package:teacher_demo/data/repository_providers.dart';
import 'package:teacher_demo/services/session_service.dart';
import 'package:teacher_demo/services/tenant_data.dart';

final demoNow = DateTime(2026, 9, 27, 18);

/// Loads the bundled Cairo font so text widths match the real app, not the test font.
Future<void> loadAppFonts() async {
  final loader = FontLoader(AppTheme.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/Cairo-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (flutterRoot != null && icons.existsSync()) {
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await iconLoader.load();
  }
}

/// Advances enough frames for zero-latency mock streams to emit and settle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Boots the full app signed in as [phone] at [path], backed by a fresh mock store.
Future<MockDatabase> bootApp(
  WidgetTester tester, {
  required String path,
  String phone = DemoAccounts.teacherPhone,
  Size size = const Size(1280, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final db = MockDatabase(SeedGenerator(now: demoNow).generate(), latency: () => Duration.zero);
  final container = ProviderContainer(
    overrides: [
      mockDatabaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(() => demoNow),
    ],
  );
  addTearDown(container.dispose);

  await tester.runAsync(
    () => container
        .read(sessionProvider.notifier)
        .signIn(phone: phone, password: DemoAccounts.password),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const TeacherDemoApp()),
  );
  container.read(routerProvider).go(path);
  await settle(tester);
  return db;
}
