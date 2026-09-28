import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teacher_demo/core/constants/demo_accounts.dart';
import 'package:teacher_demo/data/mock/mock_database.dart';
import 'package:teacher_demo/data/mock/seed_generator.dart';
import 'package:teacher_demo/data/models/models.dart';
import 'package:teacher_demo/data/repository_providers.dart';
import 'package:teacher_demo/services/platform_admin_service.dart';

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

  group('PlatformAdminService', () {
    test('adds a teacher with a new trial tenant and owner account', () async {
      final (c, db) = _setup();
      final tenantsBefore = db.tenants.rows.length;
      final usersBefore = db.users.rows.length;

      final tenant = await c
          .read(platformAdminServiceProvider)
          .addTeacher(
            teacherName: 'أ. سمير فوزي',
            subject: 'أحياء',
            phone: '01288889999',
            plan: SubscriptionPlan.pro,
          );

      expect(db.tenants.rows, hasLength(tenantsBefore + 1));
      expect(db.users.rows, hasLength(usersBefore + 1));
      expect(tenant.subscriptionStatus, SubscriptionStatus.trial);
      expect(tenant.subscriptionPlan, SubscriptionPlan.pro);
      final owner = db.users.rows.singleWhere((u) => u.id == tenant.ownerUserId);
      expect(owner.role, UserRole.teacher);
      expect(owner.password, PlatformAdminService.defaultPassword);
      // A schedule-periods row is created for every new tenant.
      expect(db.periods.rows.where((p) => p.tenantId == tenant.id), hasLength(1));
    });

    test('rejects a phone already in use', () async {
      final (c, db) = _setup();
      await expectLater(
        c
            .read(platformAdminServiceProvider)
            .addTeacher(
              teacherName: 'x',
              subject: 'x',
              phone: DemoAccounts.teacherPhone,
              plan: SubscriptionPlan.basic,
            ),
        throwsA(isA<PlatformAdminException>()),
      );
    });

    test('activates and deactivates a tenant', () async {
      final (c, db) = _setup();
      final tenant = db.tenants.rows.firstWhere((t) => t.id == SeedGenerator.mainTenantId);
      expect(tenant.subscriptionStatus, SubscriptionStatus.active);

      await c.read(platformAdminServiceProvider).setStatus(tenant, SubscriptionStatus.expired);
      expect(
        db.tenants.rows.singleWhere((t) => t.id == tenant.id).subscriptionStatus,
        SubscriptionStatus.expired,
      );

      await c.read(platformAdminServiceProvider).setStatus(tenant, SubscriptionStatus.active);
      expect(
        db.tenants.rows.singleWhere((t) => t.id == tenant.id).subscriptionStatus,
        SubscriptionStatus.active,
      );
    });
  });

  group('tenantStudentCountProvider', () {
    test('counts only active enrollments of the given tenant', () async {
      final (c, db) = _setup();
      final count = await awaitStream(c, tenantStudentCountProvider(SeedGenerator.mainTenantId));
      expect(count, SeedGenerator.mainStudentCount);
    });
  });
}
