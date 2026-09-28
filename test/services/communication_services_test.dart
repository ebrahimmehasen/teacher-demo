import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teacher_demo/data/mock/mock_database.dart';
import 'package:teacher_demo/data/mock/seed_generator.dart';
import 'package:teacher_demo/data/models/models.dart';
import 'package:teacher_demo/data/repository_providers.dart';
import 'package:teacher_demo/services/announcement_service.dart';
import 'package:teacher_demo/services/complaint_service.dart';
import 'package:teacher_demo/services/group_service.dart';
import 'package:teacher_demo/services/request_approval_service.dart';
import 'package:teacher_demo/services/staff_service.dart';

const _main = SeedGenerator.mainTenantId;

(ProviderContainer, MockDatabase) _setup() {
  final db = MockDatabase(
    SeedGenerator(now: DateTime(2026, 9, 27, 12)).generate(),
    latency: () => Duration.zero,
  );
  final c = ProviderContainer(overrides: [mockDatabaseProvider.overrideWithValue(db)]);
  addTearDown(c.dispose);
  return (c, db);
}

Group _group(MockDatabase db, String id) => db.groups.rows.singleWhere((g) => g.id == id);

Request _pendingChangeGroupRequest(
  MockDatabase db, {
  required String studentId,
  required String targetGroupId,
}) => Request(
  id: 'req-$studentId',
  tenantId: _main,
  fromUserId: studentId,
  fromRole: UserRole.student,
  studentId: studentId,
  type: RequestType.changeGroup,
  text: 'عايز أنقل',
  requestedGroupId: targetGroupId,
  createdAt: DateTime(2026, 9, 27),
);

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('RequestApprovalService (rule 12)', () {
    test('approving a change-group request moves the enrollment', () async {
      final (c, db) = _setup();
      final studentId = SeedGenerator.studentUserId(0);
      final request = _pendingChangeGroupRequest(
        db,
        studentId: studentId,
        targetGroupId: 'grp-a-7',
      );
      db.requests.insert(request);
      final before = db.notifications.rows.length;

      await c
          .read(requestApprovalServiceProvider)
          .approve(
            request,
            now: DateTime(2026, 9, 28),
            targetGroup: _group(db, 'grp-a-7'),
            tenantEnrollments: db.enrollments.rows,
          );

      final enrollment = db.enrollments.rows.singleWhere(
        (e) => e.studentId == studentId && e.tenantId == _main,
      );
      expect(enrollment.groupId, 'grp-a-7');
      final saved = db.requests.rows.singleWhere((r) => r.id == request.id);
      expect(saved.status, RequestStatus.approved);

      final sent = db.notifications.rows.skip(before).toList();
      expect(sent, isNotEmpty);
      expect(sent.every((n) => n.type == NotificationType.request), isTrue);
    });

    test('approving into a full group throws CapacityException and changes nothing', () async {
      final (c, db) = _setup();
      final studentId = SeedGenerator.studentUserId(0);
      final request = _pendingChangeGroupRequest(
        db,
        studentId: studentId,
        targetGroupId: 'grp-a-8',
      );
      db.requests.insert(request);
      final before = db.enrollments.rows.singleWhere(
        (e) => e.studentId == studentId && e.tenantId == _main,
      );

      await expectLater(
        c
            .read(requestApprovalServiceProvider)
            .approve(
              request,
              now: DateTime(2026, 9, 28),
              targetGroup: _group(db, 'grp-a-8'),
              tenantEnrollments: db.enrollments.rows,
            ),
        throwsA(isA<CapacityException>()),
      );

      final after = db.enrollments.rows.singleWhere(
        (e) => e.studentId == studentId && e.tenantId == _main,
      );
      expect(after.groupId, before.groupId);
      expect(db.requests.rows.singleWhere((r) => r.id == request.id).status, RequestStatus.pending);
    });

    test('rejecting sets the status and reply without touching enrollments', () async {
      final (c, db) = _setup();
      final studentId = SeedGenerator.studentUserId(1);
      final request = Request(
        id: 'req-x',
        tenantId: _main,
        fromUserId: studentId,
        fromRole: UserRole.student,
        studentId: studentId,
        type: RequestType.absence,
        text: 'تعبان',
        date: DateTime(2026, 9, 29),
        createdAt: DateTime(2026, 9, 27),
      );
      db.requests.insert(request);

      await c
          .read(requestApprovalServiceProvider)
          .reject(request, reply: 'برجاء إحضار عذر', now: DateTime(2026, 9, 28));

      final saved = db.requests.rows.singleWhere((r) => r.id == request.id);
      expect(saved.status, RequestStatus.rejected);
      expect(saved.reply, 'برجاء إحضار عذر');
    });
  });

  group('ComplaintService', () {
    test('a warning notifies only the student', () async {
      final (c, db) = _setup();
      final studentId = SeedGenerator.studentUserId(0);
      final before = db.notifications.rows.length;

      await c
          .read(complaintServiceProvider)
          .send(
            tenantId: _main,
            studentId: studentId,
            kind: ComplaintKind.warning,
            text: 'التزم بالهدوء',
            byUserId: SeedGenerator.teacherUserId,
            now: DateTime(2026, 9, 27),
          );

      expect(db.complaints.rows.last.toRole, UserRole.student);
      final sent = db.notifications.rows.skip(before).toList();
      expect(sent.map((n) => n.userId).toSet(), {studentId});
    });

    test('a complaint notifies the linked parent(s), not the student', () async {
      final (c, db) = _setup();
      final studentId = SeedGenerator.studentUserId(0);
      final before = db.notifications.rows.length;

      await c
          .read(complaintServiceProvider)
          .send(
            tenantId: _main,
            studentId: studentId,
            kind: ComplaintKind.complaint,
            text: 'تكرار الغياب',
            byUserId: SeedGenerator.teacherUserId,
            now: DateTime(2026, 9, 27),
          );

      expect(db.complaints.rows.last.toRole, UserRole.parent);
      final sent = db.notifications.rows.skip(before).toList();
      expect(sent.map((n) => n.userId).toSet(), {SeedGenerator.parentUserId(0)});
    });
  });

  group('AnnouncementService (rule 9)', () {
    test('notifies every target student and their linked parents', () async {
      final (c, db) = _setup();
      final targets = {SeedGenerator.studentUserId(0), SeedGenerator.studentUserId(1)};
      final before = db.notifications.rows.length;

      await c
          .read(announcementServiceProvider)
          .create(
            tenantId: _main,
            title: 'امتحان',
            body: 'امتحان يوم الخميس',
            gradeId: 'g-a-3',
            targetStudentIds: targets,
            now: DateTime(2026, 9, 27),
          );

      expect(db.announcements.rows.last.gradeId, 'g-a-3');
      final sent = db.notifications.rows.skip(before).toList();
      expect(sent.map((n) => n.userId).toSet(), {
        SeedGenerator.studentUserId(0),
        SeedGenerator.studentUserId(1),
        SeedGenerator.parentUserId(0),
        SeedGenerator.parentUserId(1),
      });
      expect(sent.every((n) => n.type == NotificationType.announcement), isTrue);
    });
  });

  group('StaffService', () {
    test('adds a new assistant account with permissions', () async {
      final (c, db) = _setup();
      final usersBefore = db.users.rows.length;

      final member = await c
          .read(staffServiceProvider)
          .add(
            tenantId: _main,
            name: 'مساعد جديد',
            phone: '01199998888',
            type: StaffType.assistant,
            permissions: {Permission.attendance, Permission.payments},
          );

      expect(db.users.rows, hasLength(usersBefore + 1));
      final user = db.users.rows.singleWhere((u) => u.id == member.userId);
      expect(user.role, UserRole.assistant);
      expect(user.password, StaffService.defaultPassword);
      expect(member.permissions, {Permission.attendance, Permission.payments});
    });

    test('rejects a phone already staffed at this tenant', () async {
      final (c, db) = _setup();
      final existing = db.staff.rows.firstWhere((s) => s.tenantId == _main);
      final existingUser = db.users.rows.singleWhere((u) => u.id == existing.userId);

      await expectLater(
        c
            .read(staffServiceProvider)
            .add(
              tenantId: _main,
              name: 'x',
              phone: existingUser.phone,
              type: StaffType.assistant,
              permissions: {Permission.attendance},
            ),
        throwsA(isA<StaffServiceException>()),
      );
    });

    test('rejects a phone registered to a non-assistant role', () async {
      final (c, db) = _setup();
      await expectLater(
        c
            .read(staffServiceProvider)
            .add(
              tenantId: _main,
              name: 'x',
              phone: db.users.rows.singleWhere((u) => u.id == SeedGenerator.teacherUserId).phone,
              type: StaffType.assistant,
              permissions: {Permission.attendance},
            ),
        throwsA(isA<StaffServiceException>()),
      );
    });

    test('toggling permissions and removing a member', () async {
      final (c, db) = _setup();
      final member = db.staff.rows.firstWhere((s) => s.tenantId == _main);

      await c.read(staffServiceProvider).updatePermissions(member, {Permission.grades});
      expect(db.staff.rows.singleWhere((s) => s.id == member.id).permissions, {Permission.grades});

      await c.read(staffServiceProvider).remove(member);
      expect(db.staff.rows.where((s) => s.id == member.id), isEmpty);
    });
  });
}
