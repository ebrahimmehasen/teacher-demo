import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teacher_demo/core/constants/demo_accounts.dart';
import 'package:teacher_demo/data/mock/mock_database.dart';
import 'package:teacher_demo/data/mock/seed_generator.dart';
import 'package:teacher_demo/data/models/models.dart';
import 'package:teacher_demo/data/repository_providers.dart';
import 'package:teacher_demo/services/admission_service.dart';
import 'package:teacher_demo/services/assessment_service.dart';
import 'package:teacher_demo/services/attendance_service.dart';
import 'package:teacher_demo/services/group_service.dart';
import 'package:teacher_demo/services/payment_service.dart';
import 'package:teacher_demo/services/qr_token_service.dart';
import 'package:teacher_demo/services/sheet_service.dart';

const _main = SeedGenerator.mainTenantId;
// grp-a-6 meets Tuesdays at 17:00; the seed has no records after 2026-09-26.
final _tuesday1715 = DateTime(2026, 9, 29, 17, 15);

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

List<AppNotification> _notificationsSince(MockDatabase db, int before) =>
    db.notifications.rows.skip(before).toList();

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('AttendanceRecorder', () {
    final student = SeedGenerator.studentUserId(0);

    String token({String tenant = _main, String? studentId, DateTime? at}) => const QrTokenService()
        .generate(tenantId: tenant, studentId: studentId ?? student, now: at ?? _tuesday1715);

    Future<ScanPreview> check(
      AttendanceRecorder r,
      MockDatabase db,
      String raw, {
      String groupId = 'grp-a-6',
      DateTime? now,
    }) => r.check(
      raw: raw,
      tenantId: _main,
      group: _group(db, groupId),
      groupLabel: 'تالتة ثانوي – المجموعة الأولى',
      thresholdMinutes: 10,
      now: now ?? _tuesday1715,
    );

    test('scan → late preview → commit notifies student, parent and teacher', () async {
      final (c, db) = _setup();
      final recorder = c.read(attendanceRecorderProvider);

      final preview = await check(recorder, db, token());
      expect(preview.student.id, student);
      expect(preview.status, AttendanceStatus.late);
      expect(preview.lateMinutes, 15);
      expect(preview.isMakeup, isFalse);
      expect(preview.isDuplicate, isFalse);

      final before = db.notifications.rows.length;
      final record = await recorder.commit(preview, recordedBy: SeedGenerator.assistantUserId);
      expect(db.attendance.rows.last, record);
      expect(record.method, AttendanceMethod.qr);
      expect(record.date, DateTime(2026, 9, 29));

      final sent = _notificationsSince(db, before);
      expect(sent.map((n) => n.userId).toSet(), {
        student,
        SeedGenerator.parentUserId(0),
        SeedGenerator.teacherUserId,
      });
      expect(sent.every((n) => n.type == NotificationType.attendance), isTrue);
      expect(sent.first.body, contains('متأخر 15 دقيقة'));

      final again = await check(recorder, db, token());
      expect(again.isDuplicate, isTrue);

      await recorder.undo(record);
      expect(db.attendance.rows.where((a) => a.id == record.id), isEmpty);
    });

    test('rule 5: scanning in another group is a makeup', () async {
      final (c, db) = _setup();
      final preview = await check(
        c.read(attendanceRecorderProvider),
        db,
        token(),
        groupId: 'grp-a-7',
      );
      expect(preview.isMakeup, isTrue);
      final record = await c
          .read(attendanceRecorderProvider)
          .commit(preview, recordedBy: SeedGenerator.assistantUserId);
      expect(record.isMakeup, isTrue);
      expect(record.groupId, 'grp-a-7');
    });

    test('rejects expired, foreign-tenant and not-enrolled codes', () async {
      final (c, db) = _setup();
      final recorder = c.read(attendanceRecorderProvider);

      await expectLater(
        check(recorder, db, token(at: _tuesday1715.subtract(const Duration(minutes: 2)))),
        throwsA(isA<ScanRejected>().having((e) => e.message, 'message', contains('انتهت'))),
      );
      await expectLater(
        check(recorder, db, token(tenant: SeedGenerator.secondTenantId)),
        throwsA(isA<ScanRejected>().having((e) => e.message, 'message', contains('مدرس آخر'))),
      );
      // Student 60 studies with Mona only.
      await expectLater(
        check(recorder, db, token(studentId: SeedGenerator.studentUserId(60))),
        throwsA(isA<ScanRejected>().having((e) => e.message, 'message', contains('غير مسجل'))),
      );
    });

    test('manual save upserts per student and notifies only changed students', () async {
      final (c, db) = _setup();
      final group = _group(db, 'grp-a-6');
      final day = DateTime(2026, 9, 26);
      final students = db.enrollments.rows
          .where((e) => e.groupId == group.id)
          .map((e) => e.studentId)
          .toList();
      final existingBefore = db.attendance.rows
          .where((a) => a.groupId == group.id && a.date == day)
          .length;
      expect(existingBefore, students.length, reason: 'seed has Saturday records');

      final before = db.notifications.rows.length;
      await c
          .read(attendanceRecorderProvider)
          .saveManual(
            tenantId: _main,
            group: group,
            groupLabel: 'x',
            day: day,
            entries: {
              students[0]: const ManualEntry(AttendanceStatus.absentExcused, excuse: 'مرض'),
              for (final s in students.skip(1)) s: const ManualEntry(AttendanceStatus.present),
            },
            studentNames: const {},
            recordedBy: SeedGenerator.assistantUserId,
            now: DateTime(2026, 9, 26, 20),
          );

      final records = db.attendance.rows
          .where((a) => a.groupId == group.id && a.date == day)
          .toList();
      expect(records, hasLength(students.length), reason: 'updated in place, not duplicated');
      final excused = records.singleWhere((a) => a.studentId == students[0]);
      expect(excused.status, AttendanceStatus.absentExcused);
      expect(excused.excuseText, 'مرض');

      final sent = _notificationsSince(db, before);
      expect(sent.where((n) => n.userId == SeedGenerator.teacherUserId), hasLength(1));
      expect(sent.where((n) => n.userId == students[0]), hasLength(1));
    });
  });

  group('PaymentService', () {
    test('records a payment and notifies the circle', () async {
      final (c, db) = _setup();
      final student = db.users.rows.singleWhere((u) => u.id == SeedGenerator.studentUserId(0));
      final before = db.notifications.rows.length;

      final payment = await c
          .read(paymentServiceProvider)
          .record(
            tenantId: _main,
            student: student,
            month: '2026-09',
            amount: 350,
            method: PaymentMethod.vodafoneCash,
            referenceNumber: ' 123456789 ',
            recordedBy: SeedGenerator.assistantUserId,
            now: DateTime(2026, 9, 27, 18),
          );
      expect(db.payments.rows.last, payment);
      expect(payment.referenceNumber, '123456789');

      final sent = _notificationsSince(db, before);
      expect(sent.map((n) => n.userId).toSet(), {
        student.id,
        SeedGenerator.parentUserId(0),
        SeedGenerator.teacherUserId,
      });
      expect(sent.every((n) => n.type == NotificationType.payment), isTrue);
    });

    test('e-wallet payments need a reference; amounts must be positive', () async {
      final (c, db) = _setup();
      final student = db.users.rows.firstWhere((u) => u.role == UserRole.student);
      final service = c.read(paymentServiceProvider);
      Future<Payment> pay(double amount, PaymentMethod method, [String? ref]) => service.record(
        tenantId: _main,
        student: student,
        month: '2026-09',
        amount: amount,
        method: method,
        referenceNumber: ref,
        recordedBy: 'x',
        now: DateTime(2026, 9, 27),
      );
      await expectLater(pay(100, PaymentMethod.instaPay), throwsArgumentError);
      await expectLater(pay(0, PaymentMethod.cash), throwsArgumentError);
      expect((await pay(100, PaymentMethod.cash, 'ignored')).referenceNumber, isNull);
    });

    test('selectable months run from next month back five months', () {
      expect(PaymentService.selectableMonths(DateTime(2026, 1, 15)), [
        '2026-02',
        '2026-01',
        '2025-12',
        '2025-11',
        '2025-10',
        '2025-09',
        '2025-08',
      ]);
    });
  });

  group('Sheet stock (rule 10)', () {
    test('remaining, low-stock flag and oversell protection', () async {
      final (c, db) = _setup();
      final sheet = db.sheets.rows.singleWhere((s) => s.gradeId == 'g-a-3');
      final sales = db.sheetSales.rows;
      final remaining = SheetStock.remaining(sheet, sales);
      expect(remaining, 7);
      expect(SheetStock.isLow(remaining), isTrue);

      final service = c.read(sheetSaleServiceProvider);
      await expectLater(
        service.record(
          sheet: sheet,
          qty: 8,
          date: DateTime(2026, 9, 27),
          existingSales: sales,
          recordedBy: 'a',
        ),
        throwsA(isA<InsufficientStockException>()),
      );
      final sale = await service.record(
        sheet: sheet,
        qty: 2,
        date: DateTime(2026, 9, 27),
        existingSales: sales,
        recordedBy: 'a',
      );
      expect(sale.total, 2 * sheet.price);
      expect(SheetStock.remaining(sheet, db.sheetSales.rows), 5);
    });
  });

  group('AdmissionService', () {
    AdmissionService service(ProviderContainer c) => c.read(admissionServiceProvider);

    test('admits a student with a unique link code and creates the parent', () async {
      final (c, db) = _setup();
      final group = _group(db, 'grp-a-1');
      final result = await service(c).admit(
        tenantId: _main,
        name: 'يوسف أحمد',
        phone: '01299999999',
        group: group,
        schoolYear: 'أولى ثانوي',
        tenantEnrollments: db.enrollments.rows,
        now: DateTime(2026, 9, 27),
        parentName: 'أحمد يوسف',
        parentPhone: '01599999999',
      );
      expect(result.linkCode, matches(RegExp(r'^[A-Z0-9]{6}$')));
      expect(
        db.studentProfiles.rows.map((p) => p.parentLinkCode).where((c) => c == result.linkCode),
        hasLength(1),
      );
      expect(
        db.enrollments.rows.where((e) => e.studentId == result.student.id).single.groupId,
        group.id,
      );
      expect(result.parentCreated, isTrue);
      expect(result.parent!.role, UserRole.parent);
      expect(
        db.parentLinks.rows.where((l) => l.studentUserId == result.student.id).single.parentUserId,
        result.parent!.id,
      );
    });

    test('links an existing parent by phone instead of creating one', () async {
      final (c, db) = _setup();
      final result = await service(c).admit(
        tenantId: _main,
        name: 'طالب جديد',
        phone: '01288888888',
        group: _group(db, 'grp-a-1'),
        schoolYear: 'أولى ثانوي',
        tenantEnrollments: db.enrollments.rows,
        now: DateTime(2026, 9, 27),
        parentPhone: DemoAccounts.parentPhone,
      );
      expect(result.parentCreated, isFalse);
      expect(result.parent!.id, SeedGenerator.parentUserId(0));
    });

    test('rule 4 and validation: full group, duplicate phone, bad parent phone', () async {
      final (c, db) = _setup();
      final usersBefore = db.users.rows.length;
      Future<AdmissionResult> admit({
        required Group group,
        String phone = '01277777777',
        String? parentPhone,
      }) => service(c).admit(
        tenantId: _main,
        name: 'x',
        phone: phone,
        group: group,
        schoolYear: 'x',
        tenantEnrollments: db.enrollments.rows,
        now: DateTime(2026, 9, 27),
        parentPhone: parentPhone,
      );

      await expectLater(admit(group: _group(db, 'grp-a-8')), throwsA(isA<CapacityException>()));
      await expectLater(
        admit(group: _group(db, 'grp-a-1'), phone: DemoAccounts.studentPhone),
        throwsA(isA<AdmissionException>()),
      );
      await expectLater(
        admit(group: _group(db, 'grp-a-1'), parentPhone: DemoAccounts.teacherPhone),
        throwsA(isA<AdmissionException>()),
      );
      expect(db.users.rows.length, usersBefore, reason: 'nothing is created on failure');
    });
  });

  group('AssessmentService', () {
    test('saving twice updates the same result rows', () async {
      final (c, db) = _setup();
      final exam = db.assessments.rows.firstWhere((a) => a.maxScore == 30);
      final studentId = db.assessmentResults.rows
          .firstWhere((r) => r.assessmentId == exam.id)
          .studentId;
      final before = db.assessmentResults.rows.length;

      final service = c.read(assessmentServiceProvider);
      await service.saveResults(exam, {
        studentId: const ResultEntry(delivered: true, score: 27.5),
      }, db.assessmentResults.rows);
      await service.saveResults(exam, {
        studentId: const ResultEntry(delivered: true, score: 29),
      }, db.assessmentResults.rows);

      expect(db.assessmentResults.rows.length, before);
      final result = db.assessmentResults.rows.singleWhere(
        (r) => r.assessmentId == exam.id && r.studentId == studentId,
      );
      expect(result.score, 29);
    });

    test('scores above the max are rejected', () {
      final (c, db) = _setup();
      final exam = db.assessments.rows.firstWhere((a) => a.maxScore == 30);
      expect(
        () => c.read(assessmentServiceProvider).saveResults(exam, {
          's': const ResultEntry(delivered: true, score: 31),
        }, const []),
        throwsArgumentError,
      );
    });
  });
}
