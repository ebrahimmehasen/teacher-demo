import '../data/models/models.dart';

enum StudentLevel { excellent, veryGood, good, needsFollowUp }

extension StudentLevelLabel on StudentLevel {
  String get label => switch (this) {
    StudentLevel.excellent => 'ممتاز',
    StudentLevel.veryGood => 'جيد جداً',
    StudentLevel.good => 'جيد',
    StudentLevel.needsFollowUp => 'يحتاج متابعة',
  };
}

class ReportResult {
  const ReportResult({
    required this.from,
    required this.to,
    required this.totalSessions,
    required this.presentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.absentCount,
    required this.attendanceRate,
    required this.averageScorePercent,
    required this.levelScore,
    required this.level,
  });

  final DateTime from;
  final DateTime to;
  final int totalSessions;
  final int presentCount;
  final int lateCount;
  final int excusedCount;
  final int absentCount;

  /// 0–100; absent-excused counts as half a present (rule 6).
  final double attendanceRate;
  double get absenceRate => 100 - attendanceRate;

  /// 0–100 average of score/maxScore over scored assessments in range; null
  /// when there are none (homework-only or nothing graded yet).
  final double? averageScorePercent;

  /// 0–100 composite used for [level] (rule 6).
  final double levelScore;
  final StudentLevel level;
}

/// Rule 6: level = attendanceRate × weightA + averageScore% × weightG, with
/// absent-excused counted as half an absence.
abstract final class ReportService {
  static ReportResult calculate({
    required DateTime from,
    required DateTime to,
    required Iterable<Attendance> attendance,
    required Iterable<AssessmentResult> results,
    required Map<String, Assessment> assessmentsById,
    required int attendanceWeight,
    required int gradesWeight,
  }) {
    final inRange = attendance.where((a) => !a.date.isBefore(from) && !a.date.isAfter(to)).toList();

    var present = 0, late = 0, excused = 0, absent = 0;
    var credit = 0.0;
    for (final a in inRange) {
      switch (a.status) {
        case AttendanceStatus.present:
          present++;
          credit += 1;
        case AttendanceStatus.late:
          late++;
          credit += 1;
        case AttendanceStatus.absentExcused:
          excused++;
          credit += 0.5;
        case AttendanceStatus.absent:
          absent++;
      }
    }
    final attendanceRate = inRange.isEmpty ? 0.0 : credit / inRange.length * 100;

    final scores = <double>[
      for (final r in results)
        if (assessmentsById[r.assessmentId] case final a?)
          if (a.maxScore != null &&
              r.score != null &&
              !a.date.isBefore(from) &&
              !a.date.isAfter(to))
            r.score! / a.maxScore! * 100,
    ];
    final averageScore = scores.isEmpty ? null : scores.reduce((x, y) => x + y) / scores.length;

    // With nothing graded yet, judge on attendance alone rather than
    // penalizing the student for a zero average.
    final levelScore = averageScore == null
        ? attendanceRate
        : attendanceRate * (attendanceWeight / 100) + averageScore * (gradesWeight / 100);

    final level = levelScore >= 85
        ? StudentLevel.excellent
        : levelScore >= 70
        ? StudentLevel.veryGood
        : levelScore >= 55
        ? StudentLevel.good
        : StudentLevel.needsFollowUp;

    return ReportResult(
      from: from,
      to: to,
      totalSessions: inRange.length,
      presentCount: present,
      lateCount: late,
      excusedCount: excused,
      absentCount: absent,
      attendanceRate: attendanceRate,
      averageScorePercent: averageScore,
      levelScore: levelScore,
      level: level,
    );
  }
}
