import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teacher_demo/core/constants/demo_accounts.dart';
import 'package:teacher_demo/data/mock/mock_database.dart';
import 'package:teacher_demo/data/mock/seed_generator.dart';
import 'package:teacher_demo/data/models/models.dart';
import 'package:teacher_demo/data/repository_providers.dart';
import 'package:teacher_demo/services/request_service.dart';
import 'package:teacher_demo/services/session_service.dart';
import 'package:teacher_demo/services/student_context.dart';
import 'package:teacher_demo/services/tenant_data.dart';

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

  group('activeStudent* providers (student role)', () {
    test('resolve to the signed-in student in the current tenant', () async {
      final (c, db) = _setup();
      await c
          .read(sessionProvider.notifier)
          .signIn(phone: DemoAccounts.studentPhone, password: DemoAccounts.password);
      await awaitStream(c, groupsProvider);
      await awaitStream(c, gradesProvider);
      await awaitStream(c, activeStudentEnrollmentsProvider);

      expect(c.read(activeStudentIdProvider), SeedGenerator.studentUserId(0));
      final tenantEnrollments = c.read(activeStudentTenantEnrollmentsProvider);
      expect(tenantEnrollments, hasLength(1));
      expect(tenantEnrollments.single.groupId, 'grp-a-6');

      final groups = c.read(activeStudentGroupsProvider);
      expect(groups.map((g) => g.id), ['grp-a-6']);
      final grades = c.read(activeStudentGradesProvider);
      expect(grades.single.name, 'تالتة ثانوي');
    });

    test('switching tenant moves the student/parent/grade context to chemistry', () async {
      final (c, db) = _setup();
      await c
          .read(sessionProvider.notifier)
          .signIn(phone: DemoAccounts.studentPhone, password: DemoAccounts.password);
      await awaitStream(c, groupsProvider);
      await awaitStream(c, gradesProvider);
      await awaitStream(c, activeStudentEnrollmentsProvider);

      c.read(sessionProvider.notifier).selectTenant(SeedGenerator.secondTenantId);
      await awaitStream(c, groupsProvider);
      await awaitStream(c, gradesProvider);

      final groups = c.read(activeStudentGroupsProvider);
      expect(groups.single.id, 'grp-m-1');
      expect(groups.single.tenantId, SeedGenerator.secondTenantId);
      expect(c.read(activeStudentGradesProvider).single.name, 'تالتة ثانوي');
    });

    test('attendance/requests/complaints are scoped to student and tenant', () async {
      final (c, db) = _setup();
      await c
          .read(sessionProvider.notifier)
          .signIn(phone: DemoAccounts.studentPhone, password: DemoAccounts.password);
      final studentId = SeedGenerator.studentUserId(0);

      final attendance = await awaitStream(c, activeStudentAttendanceProvider);
      expect(attendance, isNotEmpty);
      expect(attendance.every((a) => a.studentId == studentId), isTrue);
      expect(attendance.every((a) => a.tenantId == SeedGenerator.mainTenantId), isTrue);

      final requests = await awaitStream(c, activeStudentRequestsProvider);
      expect(requests, isNotEmpty);
      expect(requests.every((r) => r.studentId == studentId), isTrue);

      final complaints = await awaitStream(c, activeStudentComplaintsProvider);
      expect(complaints, isNotEmpty);
      expect(complaints.every((c) => c.studentId == studentId), isTrue);
    });
  });

  group('RequestService', () {
    test('creates a request and notifies the teacher', () async {
      final (c, db) = _setup();
      final before = db.notifications.rows.length;
      final requestsBefore = db.requests.rows.length;

      final request = await c
          .read(requestServiceProvider)
          .create(
            tenantId: SeedGenerator.mainTenantId,
            studentId: SeedGenerator.studentUserId(0),
            studentName: 'مريم',
            fromUserId: SeedGenerator.studentUserId(0),
            fromRole: UserRole.student,
            type: RequestType.absence,
            text: '  عندي امتحان مدرسي  ',
            now: DateTime(2026, 9, 28),
            date: DateTime(2026, 10, 1),
          );

      expect(db.requests.rows, hasLength(requestsBefore + 1));
      expect(request.text, 'عندي امتحان مدرسي');
      expect(request.status, RequestStatus.pending);

      final sent = db.notifications.rows.skip(before).toList();
      expect(sent, hasLength(1));
      expect(sent.single.userId, SeedGenerator.teacherUserId);
      expect(sent.single.type, NotificationType.request);
      expect(sent.single.body, contains('مريم'));
      expect(sent.single.deepLink, '/teacher/requests');
    });
  });
}
