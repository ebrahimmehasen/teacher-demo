import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teacher_demo/core/constants/demo_accounts.dart';
import 'package:teacher_demo/data/mock/mock_database.dart';
import 'package:teacher_demo/data/mock/seed_generator.dart';
import 'package:teacher_demo/data/models/models.dart';
import 'package:teacher_demo/data/repository_providers.dart';
import 'package:teacher_demo/services/parent_auth_service.dart';
import 'package:teacher_demo/services/parent_context.dart';
import 'package:teacher_demo/services/session_service.dart';

import '../helpers/riverpod_helpers.dart';

(ProviderContainer, MockDatabase) _setup() {
  final db = MockDatabase(
    SeedGenerator(now: DateTime(2026, 9, 27, 12)).generate(),
    latency: () => Duration.zero,
  );
  final c = ProviderContainer(overrides: [mockDatabaseProvider.overrideWithValue(db)]);
  addTearDown(c.dispose);
  return (c, db);
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('ParentAuthService', () {
    test('signs up a new parent and rejects a taken phone', () async {
      final (c, db) = _setup();
      final service = c.read(parentAuthServiceProvider);

      final parent = await service.signUp(
        name: 'سعاد علي',
        phone: '01555554444',
        password: '123456',
      );
      expect(parent.role, UserRole.parent);
      expect(db.users.rows, contains(parent));

      await expectLater(
        service.signUp(name: 'x', phone: DemoAccounts.teacherPhone, password: '123456'),
        throwsA(isA<ParentAuthException>()),
      );
    });

    test('links a child by code and rejects a bad or duplicate code', () async {
      final (c, db) = _setup();
      final service = c.read(parentAuthServiceProvider);
      final parent = await service.signUp(
        name: 'سعاد علي',
        phone: '01555554444',
        password: '123456',
      );

      await expectLater(
        service.linkChildByCode(parent: parent, code: 'BADCOD'),
        throwsA(isA<ParentAuthException>()),
      );

      final code = db.studentProfiles.rows
          .singleWhere((p) => p.userId == SeedGenerator.studentUserId(1))
          .parentLinkCode;
      final child = await service.linkChildByCode(parent: parent, code: code.toLowerCase());
      expect(child.id, SeedGenerator.studentUserId(1));
      expect(
        db.parentLinks.rows.where(
          (l) => l.parentUserId == parent.id && l.studentUserId == child.id,
        ),
        hasLength(1),
      );

      await expectLater(
        service.linkChildByCode(parent: parent, code: code),
        throwsA(isA<ParentAuthException>()),
      );
    });
  });

  group('parentChildrenProvider', () {
    test('lists every child linked to the signed-in parent', () async {
      final (c, db) = _setup();
      await c
          .read(sessionProvider.notifier)
          .signIn(phone: DemoAccounts.parentPhone, password: DemoAccounts.password);

      final children = await awaitStream(c, parentChildrenProvider);
      expect(children.map((u) => u.id).toSet(), {
        SeedGenerator.studentUserId(0),
        SeedGenerator.studentUserId(50),
      });
    });
  });
}
