import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_demo/data/models/models.dart';
import 'package:teacher_demo/services/attendance_service.dart';
import 'package:teacher_demo/services/qr_token_service.dart';

void main() {
  group('QrTokenService (rule 7)', () {
    const qr = QrTokenService();
    final t0 = DateTime.utc(2026, 9, 26, 15, 0, 5);

    test('a fresh token verifies for the same tenant', () {
      final token = qr.generate(tenantId: 't1', studentId: 's1', now: t0);
      final result = qr.verify(token, tenantId: 't1', now: t0);
      expect(result.isValid, isTrue);
      expect(result.studentId, 's1');
      expect(token.split('|').take(2), ['t1', 's1']);
    });

    test('the previous window is accepted, older windows are expired', () {
      final token = qr.generate(tenantId: 't1', studentId: 's1', now: t0);
      final nextWindow = t0.add(const Duration(seconds: 30));
      final twoLater = t0.add(const Duration(seconds: 60));
      expect(qr.verify(token, tenantId: 't1', now: nextWindow).isValid, isTrue);
      expect(qr.verify(token, tenantId: 't1', now: twoLater).error, QrError.expired);
    });

    test('a token from the future is rejected as expired', () {
      final token = qr.generate(
        tenantId: 't1',
        studentId: 's1',
        now: t0.add(const Duration(minutes: 5)),
      );
      expect(qr.verify(token, tenantId: 't1', now: t0).error, QrError.expired);
    });

    test('tampering with any part breaks the signature', () {
      final token = qr.generate(tenantId: 't1', studentId: 's1', now: t0);
      final forged = token.replaceFirst('s1', 's2');
      expect(qr.verify(forged, tenantId: 't1', now: t0).error, QrError.badSignature);
      final otherSecret = const QrTokenService(secret: 'other')
          .generate(tenantId: 't1', studentId: 's1', now: t0);
      expect(qr.verify(otherSecret, tenantId: 't1', now: t0).error, QrError.badSignature);
    });

    test('a valid token of another tenant is rejected', () {
      final token = qr.generate(tenantId: 't2', studentId: 's1', now: t0);
      expect(qr.verify(token, tenantId: 't1', now: t0).error, QrError.otherTenant);
    });

    test('garbage is malformed', () {
      for (final raw in ['', 'hello', 'a|b|c', 'a|b|notanumber|sig', 'https://example.com']) {
        expect(
          qr.verify(raw, tenantId: 't1', now: t0).error,
          QrError.malformed,
          reason: raw,
        );
      }
    });

    test('remaining counts down within the 30 s window', () {
      final start = DateTime.fromMillisecondsSinceEpoch(qr.windowAt(t0) * 30 * 1000);
      expect(qr.remaining(start), const Duration(seconds: 30));
      expect(qr.remaining(start.add(const Duration(seconds: 12))), const Duration(seconds: 18));
    });
  });

  group('AttendanceRules', () {
    const start = ClockTime(17, 0);
    final day = DateTime(2026, 9, 26);

    (AttendanceStatus, int) classify(int minutesAfter) => AttendanceRules.classify(
      scanTime: start.onDate(day).add(Duration(minutes: minutesAfter)),
      sessionStart: start,
      thresholdMinutes: 10,
    );

    test('rule 3: late only when strictly more than the threshold', () {
      expect(classify(-15), (AttendanceStatus.present, 0));
      expect(classify(10), (AttendanceStatus.present, 0));
      expect(classify(11), (AttendanceStatus.late, 11));
      expect(classify(45), (AttendanceStatus.late, 45));
    });

    test('no session that day counts as present', () {
      expect(AttendanceRules.classify(scanTime: day, sessionStart: null, thresholdMinutes: 10), (
        AttendanceStatus.present,
        0,
      ));
    });

    test('current group is the running one, else the next one today', () {
      Group g(String id, int hour) => Group(
        id: id,
        tenantId: 't',
        gradeId: 'g',
        number: 1,
        type: GroupType.public,
        capacity: 10,
        sessions: [
          GroupSession(
            weekday: day.weekday,
            periodIndex: 0,
            startTime: ClockTime(hour, 0),
            endTime: ClockTime(hour, 0).addMinutes(90),
          ),
        ],
      );
      final groups = [g('early', 9), g('late', 17)];
      expect(AttendanceRules.currentGroup(groups, DateTime(2026, 9, 26, 9, 45))?.id, 'early');
      expect(AttendanceRules.currentGroup(groups, DateTime(2026, 9, 26, 16, 40))?.id, 'late');
      expect(AttendanceRules.currentGroup(groups, DateTime(2026, 9, 26, 12))?.id, 'late');
      expect(AttendanceRules.currentGroup(groups, DateTime(2026, 9, 26, 22)), isNull);
    });
  });
}
