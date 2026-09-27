import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_demo/core/constants/demo_accounts.dart';
import 'package:teacher_demo/data/mock/mock_database.dart';
import 'package:teacher_demo/data/mock/seed_generator.dart';
import 'package:teacher_demo/data/models/models.dart';
import 'package:teacher_demo/data/repository_providers.dart';
import 'package:teacher_demo/services/session_service.dart';

ProviderContainer _container() {
  final db = MockDatabase(
    SeedGenerator(now: DateTime(2026, 9, 27, 12)).generate(),
    latency: () => Duration.zero,
  );
  final container = ProviderContainer(overrides: [mockDatabaseProvider.overrideWithValue(db)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('SessionController', () {
    Future<Session> signIn(ProviderContainer c, String phone) async {
      await c.read(sessionProvider.notifier).signIn(phone: phone, password: DemoAccounts.password);
      // Read into a typed local: Riverpod 3's read() mis-infers under a `return ...!` context.
      final Session? session = c.read(sessionProvider);
      return session!;
    }

    test('resolves the tenant for every demo role', () async {
      final c = _container();

      final teacher = await signIn(c, DemoAccounts.teacherPhone);
      expect(teacher.role, UserRole.teacher);
      expect(teacher.tenantId, SeedGenerator.mainTenantId);

      final assistant = await signIn(c, DemoAccounts.assistantPhone);
      expect(assistant.tenantId, SeedGenerator.mainTenantId);

      final student = await signIn(c, DemoAccounts.studentPhone);
      expect(student.activeStudentId, student.user.id);
      expect(student.tenantId, isNotNull);

      final parent = await signIn(c, DemoAccounts.parentPhone);
      expect(parent.activeStudentId, SeedGenerator.studentUserId(0));
      expect(parent.tenantId, isNotNull);

      final admin = await signIn(c, DemoAccounts.platformAdminPhone);
      expect(admin.tenantId, isNull);
    });

    test('rejects wrong credentials and signs out', () async {
      final c = _container();
      await expectLater(
        c.read(sessionProvider.notifier).signIn(phone: DemoAccounts.teacherPhone, password: 'x'),
        throwsA(isA<AuthFailure>()),
      );
      expect(c.read(sessionProvider), isNull);

      await signIn(c, DemoAccounts.teacherPhone);
      c.read(sessionProvider.notifier).signOut();
      expect(c.read(sessionProvider), isNull);
    });

    test('parent can switch child and student can switch teacher', () async {
      final c = _container();
      await signIn(c, DemoAccounts.parentPhone);
      await c.read(sessionProvider.notifier).selectChild(SeedGenerator.studentUserId(50));
      expect(c.read(sessionProvider)!.activeStudentId, SeedGenerator.studentUserId(50));
      expect(c.read(sessionProvider)!.tenantId, SeedGenerator.mainTenantId);

      await signIn(c, DemoAccounts.studentPhone);
      c.read(sessionProvider.notifier).selectTenant(SeedGenerator.secondTenantId);
      expect(c.read(sessionProvider)!.tenantId, SeedGenerator.secondTenantId);
    });
  });

  group('Mock store', () {
    test('watchers are scoped to their tenant and update live on writes', () async {
      final c = _container();
      final repo = c.read(announcementRepositoryProvider);

      final emissions = <List<Announcement>>[];
      final sub = repo.watchByTenant(SeedGenerator.mainTenantId).listen(emissions.add);
      await pumpEventQueue();
      expect(emissions.last.every((a) => a.tenantId == SeedGenerator.mainTenantId), isTrue);
      final before = emissions.last.length;

      await repo.add(
        Announcement(
          id: 'new',
          tenantId: SeedGenerator.mainTenantId,
          title: 't',
          body: 'b',
          createdAt: DateTime(2026, 9, 27, 13),
        ),
      );
      await repo.add(
        Announcement(
          id: 'other-tenant',
          tenantId: SeedGenerator.secondTenantId,
          title: 't',
          body: 'b',
          createdAt: DateTime(2026, 9, 27, 13),
        ),
      );
      await pumpEventQueue();

      expect(emissions.last, hasLength(before + 1));
      expect(emissions.last.first.id, 'new');
      await sub.cancel();
    });

    test('unread notification count reacts to markAllRead', () async {
      final c = _container();
      final repo = c.read(notificationRepositoryProvider);
      final userId = SeedGenerator.teacherUserId;

      final emissions = <List<AppNotification>>[];
      final sub = repo.watchForUser(userId).listen(emissions.add);
      await pumpEventQueue();
      expect(emissions.last.where((n) => !n.read), isNotEmpty);

      await repo.markAllRead(userId);
      await pumpEventQueue();
      expect(emissions.last.where((n) => !n.read), isEmpty);
      await sub.cancel();
    });
  });
}
