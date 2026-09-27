import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/labels.dart';
import '../core/utils/date_utils.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';
import 'notification_service.dart';
import 'qr_token_service.dart';

abstract final class AttendanceRules {
  /// Rule 3: scanTime − session start > threshold ⇒ late with lateMinutes.
  static (AttendanceStatus, int) classify({
    required DateTime scanTime,
    required ClockTime? sessionStart,
    required int thresholdMinutes,
  }) {
    if (sessionStart == null) return (AttendanceStatus.present, 0);
    final minutes = scanTime.difference(sessionStart.onDate(scanTime)).inMinutes;
    return minutes > thresholdMinutes
        ? (AttendanceStatus.late, minutes)
        : (AttendanceStatus.present, 0);
  }

  static GroupSession? sessionOn(Group group, DateTime day) =>
      group.sessions.where((s) => s.weekday == day.weekday).firstOrNull;

  /// The group running around [now] (from 30 min before start to the end),
  /// else the next one today, else null.
  static Group? currentGroup(Iterable<Group> groups, DateTime now) {
    final minute = now.hour * 60 + now.minute;
    Group? next;
    var nextStart = 24 * 60;
    for (final g in groups) {
      final s = sessionOn(g, now);
      if (s == null) continue;
      if (minute >= s.startTime.inMinutes - 30 && minute <= s.endTime.inMinutes) return g;
      if (s.startTime.inMinutes > minute && s.startTime.inMinutes < nextStart) {
        next = g;
        nextStart = s.startTime.inMinutes;
      }
    }
    return next;
  }

  static String statusSentence(AttendanceStatus status, int lateMinutes) => switch (status) {
    AttendanceStatus.present => 'حاضر',
    AttendanceStatus.late => 'متأخر $lateMinutes دقيقة',
    AttendanceStatus.absentExcused => 'غائب بعذر',
    AttendanceStatus.absent => 'غائب',
  };
}

/// What a scan would record, before the assistant confirms it.
class ScanPreview {
  const ScanPreview({
    required this.tenantId,
    required this.student,
    required this.enrollment,
    required this.group,
    required this.groupLabel,
    required this.scanTime,
    required this.status,
    required this.lateMinutes,
    this.existing,
  });

  final String tenantId;
  final User student;
  final Enrollment enrollment;
  final Group group;
  final String groupLabel;
  final DateTime scanTime;
  final AttendanceStatus status;
  final int lateMinutes;

  /// Already recorded for this group today.
  final Attendance? existing;

  /// Rule 5: attending a group other than their own.
  bool get isMakeup => enrollment.groupId != group.id;
  bool get isDuplicate => existing != null;
}

class ScanRejected implements Exception {
  const ScanRejected(this.message);
  final String message;

  @override
  String toString() => message;
}

class ManualEntry {
  const ManualEntry(this.status, {this.lateMinutes = 0, this.excuse});
  final AttendanceStatus status;
  final int lateMinutes;
  final String? excuse;
}

class AttendanceRecorder {
  AttendanceRecorder({
    required this.qr,
    required this.users,
    required this.enrollments,
    required this.attendance,
    required this.notifier,
  });

  final QrTokenService qr;
  final UserRepository users;
  final EnrollmentRepository enrollments;
  final AttendanceRepository attendance;
  final ActivityNotifier notifier;
  static const _uuid = Uuid();

  /// Validates a scanned code; throws [ScanRejected] with a user-facing message.
  Future<ScanPreview> check({
    required String raw,
    required String tenantId,
    required Group group,
    required String groupLabel,
    required int thresholdMinutes,
    required DateTime now,
  }) async {
    final verification = qr.verify(raw, tenantId: tenantId, now: now);
    if (!verification.isValid) throw ScanRejected(verification.error!.message);
    final studentId = verification.studentId!;

    final enrollment = (await enrollments.getForStudent(studentId))
        .where((e) => e.tenantId == tenantId && e.active)
        .firstOrNull;
    if (enrollment == null) throw const ScanRejected('الطالب غير مسجل عند هذا المدرس');
    final student = await users.getById(studentId);
    if (student == null) throw const ScanRejected('لم يتم العثور على الطالب');

    final day = AppDates.dateOnly(now);
    final existing = await attendance.query(
      tenantId,
      from: day,
      to: day,
      studentId: studentId,
      groupId: group.id,
    );
    final (status, lateMinutes) = AttendanceRules.classify(
      scanTime: now,
      sessionStart: AttendanceRules.sessionOn(group, day)?.startTime,
      thresholdMinutes: thresholdMinutes,
    );
    return ScanPreview(
      tenantId: tenantId,
      student: student,
      enrollment: enrollment,
      group: group,
      groupLabel: groupLabel,
      scanTime: now,
      status: status,
      lateMinutes: lateMinutes,
      existing: existing.firstOrNull,
    );
  }

  Future<Attendance> commit(ScanPreview preview, {required String recordedBy}) async {
    final record = Attendance(
      id: _uuid.v4(),
      tenantId: preview.tenantId,
      studentId: preview.student.id,
      groupId: preview.group.id,
      date: AppDates.dateOnly(preview.scanTime),
      status: preview.status,
      lateMinutes: preview.lateMinutes,
      scanTime: preview.scanTime,
      method: AttendanceMethod.qr,
      isMakeup: preview.isMakeup,
      recordedBy: recordedBy,
    );
    await attendance.add(record);

    final time = AppDates.time(preview.scanTime);
    final detail = [
      if (preview.status == AttendanceStatus.late) ' (متأخر ${preview.lateMinutes} دقيقة)',
      if (preview.isMakeup) ' – حصة تعويض',
    ].join();
    final name = preview.student.name;
    await notifier.notifyStudentCircle(
      tenantId: preview.tenantId,
      studentId: preview.student.id,
      type: NotificationType.attendance,
      now: preview.scanTime,
      message: EventMessage(
        title: preview.status == AttendanceStatus.late ? 'حضور متأخر' : 'تسجيل حضور',
        forStudent: 'تم تسجيل حضورك في ${preview.groupLabel} الساعة $time$detail.',
        forParent: 'تم تسجيل حضور $name في ${preview.groupLabel} الساعة $time$detail.',
        forTeacher: '$name حضر ${preview.groupLabel} الساعة $time$detail.',
        teacherLink: '/teacher/attendance',
      ),
    );
    return record;
  }

  Future<void> undo(Attendance record) => attendance.delete(record.tenantId, record.id);

  /// Upserts one record per student for [group] on [day] and notifies each circle.
  Future<void> saveManual({
    required String tenantId,
    required Group group,
    required String groupLabel,
    required DateTime day,
    required Map<String, ManualEntry> entries,
    required Map<String, String> studentNames,
    required String recordedBy,
    required DateTime now,
  }) async {
    final date = AppDates.dateOnly(day);
    final existing = {
      for (final a in await attendance.query(tenantId, from: date, to: date, groupId: group.id))
        a.studentId: a,
    };
    final records = [
      for (final MapEntry(key: studentId, value: entry) in entries.entries)
        Attendance(
          id: existing[studentId]?.id ?? _uuid.v4(),
          tenantId: tenantId,
          studentId: studentId,
          groupId: group.id,
          date: date,
          status: entry.status,
          lateMinutes: entry.status == AttendanceStatus.late ? entry.lateMinutes : 0,
          scanTime: existing[studentId]?.scanTime,
          method: existing[studentId]?.method ?? AttendanceMethod.manual,
          isMakeup: existing[studentId]?.isMakeup ?? false,
          excuseText: entry.status == AttendanceStatus.absentExcused ? entry.excuse : null,
          recordedBy: recordedBy,
        ),
    ];
    await attendance.upsertAll(records);

    // Only students whose status changed hear about it.
    final changed = records.where((r) {
      final before = existing[r.studentId];
      return before == null || before.status != r.status || before.lateMinutes != r.lateMinutes;
    });
    final dateText = AppDates.dayMonth(date);
    await notifier.notifyStudents(
      tenantId: tenantId,
      type: NotificationType.attendance,
      now: now,
      events: [
        for (final r in changed)
          (
            r.studentId,
            EventMessage(
              title: 'الحضور – ${r.status.label}',
              forStudent:
                  'تم تسجيلك ${AttendanceRules.statusSentence(r.status, r.lateMinutes)} '
                  'في حصة $groupLabel يوم $dateText.',
              forParent:
                  '${studentNames[r.studentId] ?? 'الطالب'} '
                  '${AttendanceRules.statusSentence(r.status, r.lateMinutes)} '
                  'في حصة $groupLabel يوم $dateText.',
            ),
          ),
      ],
    );
    final counts = {
      for (final s in AttendanceStatus.values) s: records.where((r) => r.status == s).length,
    };
    await notifier.notifyTeacher(
      tenantId: tenantId,
      type: NotificationType.attendance,
      title: 'تسجيل حضور يدوي',
      body:
          '$groupLabel – $dateText: حاضر ${counts[AttendanceStatus.present]}، '
          'متأخر ${counts[AttendanceStatus.late]}، غائب بعذر ${counts[AttendanceStatus.absentExcused]}، '
          'غائب ${counts[AttendanceStatus.absent]}.',
      now: now,
      deepLink: '/teacher/attendance',
    );
  }
}

final attendanceRecorderProvider = Provider(
  (ref) => AttendanceRecorder(
    qr: ref.watch(qrTokenServiceProvider),
    users: ref.watch(userRepositoryProvider),
    enrollments: ref.watch(enrollmentRepositoryProvider),
    attendance: ref.watch(attendanceRepositoryProvider),
    notifier: ref.watch(activityNotifierProvider),
  ),
);
