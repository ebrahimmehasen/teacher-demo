import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_demo/data/models/models.dart';
import 'package:teacher_demo/services/report_service.dart';

Attendance _att(int day, AttendanceStatus status) => Attendance(
  id: 'a$day',
  tenantId: 't',
  studentId: 's',
  groupId: 'g',
  date: DateTime(2026, 9, day),
  status: status,
  method: AttendanceMethod.manual,
  recordedBy: 'x',
);

Assessment _exam(String id, int day, double maxScore) => Assessment(
  id: id,
  tenantId: 't',
  gradeId: 'grade',
  type: AssessmentType.exam,
  title: id,
  date: DateTime(2026, 9, day),
  maxScore: maxScore,
);

AssessmentResult _result(String assessmentId, double? score) => AssessmentResult(
  id: '$assessmentId-r',
  tenantId: 't',
  assessmentId: assessmentId,
  studentId: 's',
  delivered: score != null,
  score: score,
);

void main() {
  final range = (from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 30));

  group('ReportService.calculate (rule 6)', () {
    test('attendance rate counts present and late fully, excused as half, absent as zero', () {
      final result = ReportService.calculate(
        from: range.from,
        to: range.to,
        attendance: [
          _att(1, AttendanceStatus.present),
          _att(2, AttendanceStatus.late),
          _att(3, AttendanceStatus.absentExcused),
          _att(4, AttendanceStatus.absent),
        ],
        results: const [],
        assessmentsById: const {},
        attendanceWeight: 40,
        gradesWeight: 60,
      );
      // (1 + 1 + 0.5 + 0) / 4 = 62.5%
      expect(result.attendanceRate, closeTo(62.5, 0.001));
      expect(result.absenceRate, closeTo(37.5, 0.001));
      expect(result.presentCount, 1);
      expect(result.lateCount, 1);
      expect(result.excusedCount, 1);
      expect(result.absentCount, 1);
      expect(result.totalSessions, 4);
    });

    test('records outside the range are excluded', () {
      final result = ReportService.calculate(
        from: DateTime(2026, 9, 10),
        to: DateTime(2026, 9, 20),
        attendance: [
          _att(5, AttendanceStatus.absent),
          _att(15, AttendanceStatus.present),
          _att(25, AttendanceStatus.absent),
        ],
        results: const [],
        assessmentsById: const {},
        attendanceWeight: 40,
        gradesWeight: 60,
      );
      expect(result.totalSessions, 1);
      expect(result.attendanceRate, 100);
    });

    test('average score is the mean of score/maxScore over graded assessments in range', () {
      final exam1 = _exam('e1', 5, 50);
      final exam2 = _exam('e2', 10, 20);
      final result = ReportService.calculate(
        from: range.from,
        to: range.to,
        attendance: const [],
        results: [_result('e1', 45), _result('e2', 10)],
        assessmentsById: {'e1': exam1, 'e2': exam2},
        attendanceWeight: 40,
        gradesWeight: 60,
      );
      // 45/50=90%, 10/20=50% -> average 70%
      expect(result.averageScorePercent, closeTo(70, 0.001));
    });

    test('homework without a maxScore and ungraded results are skipped', () {
      final homework = Assessment(
        id: 'h1',
        tenantId: 't',
        gradeId: 'grade',
        type: AssessmentType.homework,
        title: 'h',
        date: DateTime(2026, 9, 5),
      );
      final exam = _exam('e1', 6, 30);
      final result = ReportService.calculate(
        from: range.from,
        to: range.to,
        attendance: const [],
        results: [_result('h1', null), _result('e1', 27)],
        assessmentsById: {'h1': homework, 'e1': exam},
        attendanceWeight: 40,
        gradesWeight: 60,
      );
      expect(result.averageScorePercent, closeTo(90, 0.001));
    });

    test('with no graded results, the level is judged on attendance alone', () {
      final result = ReportService.calculate(
        from: range.from,
        to: range.to,
        attendance: [_att(1, AttendanceStatus.present), _att(2, AttendanceStatus.present)],
        results: const [],
        assessmentsById: const {},
        attendanceWeight: 40,
        gradesWeight: 60,
      );
      expect(result.averageScorePercent, isNull);
      expect(result.levelScore, 100);
      expect(result.level, StudentLevel.excellent);
    });

    test('level score weights attendance and grades per the tenant settings', () {
      final exam = _exam('e1', 5, 100);
      final result = ReportService.calculate(
        from: range.from,
        to: range.to,
        attendance: [
          _att(1, AttendanceStatus.present),
          _att(2, AttendanceStatus.present),
          _att(3, AttendanceStatus.absent),
        ],
        results: [_result('e1', 60)],
        assessmentsById: {'e1': exam},
        attendanceWeight: 40,
        gradesWeight: 60,
      );
      // attendance 66.67%, score 60% -> 66.67*0.4 + 60*0.6 = 62.67
      expect(result.levelScore, closeTo(62.67, 0.01));
      expect(result.level, StudentLevel.good);
    });

    test('level thresholds: 85 excellent, 70 very good, 55 good, below needs follow-up', () {
      ReportResult withScore(double attendanceRate, double score) => ReportService.calculate(
        from: range.from,
        to: range.to,
        attendance: [
          for (var i = 0; i < 100; i++)
            _att(
              1 + i % 28,
              i < attendanceRate ? AttendanceStatus.present : AttendanceStatus.absent,
            ),
        ],
        results: [_result('e1', score)],
        assessmentsById: {'e1': _exam('e1', 5, 100)},
        attendanceWeight: 50,
        gradesWeight: 50,
      );
      expect(withScore(100, 100).level, StudentLevel.excellent);
      expect(withScore(80, 70).level, StudentLevel.veryGood);
      expect(withScore(60, 55).level, StudentLevel.good);
      expect(withScore(20, 20).level, StudentLevel.needsFollowUp);
    });
  });
}
