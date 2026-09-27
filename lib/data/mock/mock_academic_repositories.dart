import '../models/models.dart';
import '../repositories/repositories.dart';
import 'mock_database.dart';

class MockGradeRepository implements GradeRepository {
  MockGradeRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<Grade>> watchByTenant(String tenantId) =>
      _db.grades.watch((g) => g.tenantId == tenantId);

  @override
  Future<Grade> add(Grade grade) async {
    await _db.delay();
    _db.grades.insert(grade);
    return grade;
  }

  @override
  Future<void> update(Grade grade) async {
    await _db.delay();
    _db.grades.replace(grade);
  }

  @override
  Future<void> delete(String tenantId, String id) async {
    await _db.delay();
    _db.grades.removeWhere((g) => g.tenantId == tenantId && g.id == id);
  }
}

class MockGroupRepository implements GroupRepository {
  MockGroupRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<Group>> watchByTenant(String tenantId) =>
      _db.groups.watch((g) => g.tenantId == tenantId, sort: (a, b) => a.number.compareTo(b.number));

  @override
  Future<Group?> getById(String tenantId, String id) async {
    await _db.delay();
    return _db.groups.firstWhereOrNull((g) => g.tenantId == tenantId && g.id == id);
  }

  @override
  Future<Group> add(Group group) async {
    await _db.delay();
    _db.groups.insert(group);
    return group;
  }

  @override
  Future<void> update(Group group) async {
    await _db.delay();
    _db.groups.replace(group);
  }

  @override
  Future<void> delete(String tenantId, String id) async {
    await _db.delay();
    _db.groups.removeWhere((g) => g.tenantId == tenantId && g.id == id);
  }

  @override
  Stream<SchedulePeriods> watchPeriods(String tenantId) => _db.periods
      .watch((p) => p.tenantId == tenantId)
      .map((rows) => rows.isEmpty ? SchedulePeriods(tenantId: tenantId) : rows.first);

  @override
  Future<void> setPeriods(SchedulePeriods periods) async {
    await _db.delay();
    _db.periods.upsert(periods);
  }
}

class MockEnrollmentRepository implements EnrollmentRepository {
  MockEnrollmentRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<Enrollment>> watchByTenant(String tenantId) =>
      _db.enrollments.watch((e) => e.tenantId == tenantId);

  @override
  Stream<List<Enrollment>> watchForStudent(String studentId) =>
      _db.enrollments.watch((e) => e.studentId == studentId);

  @override
  Future<List<Enrollment>> getForStudent(String studentId) async {
    await _db.delay();
    return _db.enrollments.where((e) => e.studentId == studentId);
  }

  @override
  Future<Enrollment> add(Enrollment enrollment) async {
    await _db.delay();
    _db.enrollments.insert(enrollment);
    return enrollment;
  }

  @override
  Future<void> update(Enrollment enrollment) async {
    await _db.delay();
    _db.enrollments.replace(enrollment);
  }

  @override
  Future<void> updateAll(List<Enrollment> enrollments) async {
    await _db.delay();
    final byId = {for (final e in enrollments) e.id: e};
    _db.enrollments.updateWhere((e) => byId.containsKey(e.id), (e) => byId[e.id]!);
  }
}

class MockAttendanceRepository implements AttendanceRepository {
  MockAttendanceRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<Attendance>> watchByTenant(
    String tenantId, {
    DateTime? from,
    DateTime? to,
    String? studentId,
    String? groupId,
  }) => _db.attendance.watch(
    (a) =>
        a.tenantId == tenantId &&
        (from == null || !a.date.isBefore(from)) &&
        (to == null || !a.date.isAfter(to)) &&
        (studentId == null || a.studentId == studentId) &&
        (groupId == null || a.groupId == groupId),
    sort: (a, b) => b.date.compareTo(a.date),
  );

  @override
  Future<Attendance> add(Attendance attendance) async {
    await _db.delay();
    _db.attendance.insert(attendance);
    return attendance;
  }

  @override
  Future<void> update(Attendance attendance) async {
    await _db.delay();
    _db.attendance.replace(attendance);
  }

  @override
  Future<void> delete(String tenantId, String id) async {
    await _db.delay();
    _db.attendance.removeWhere((a) => a.tenantId == tenantId && a.id == id);
  }
}

class MockAssessmentRepository implements AssessmentRepository {
  MockAssessmentRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<Assessment>> watchAssessments(String tenantId) => _db.assessments.watch(
    (a) => a.tenantId == tenantId,
    sort: (a, b) => b.date.compareTo(a.date),
  );

  @override
  Stream<List<AssessmentResult>> watchResults(
    String tenantId, {
    String? assessmentId,
    String? studentId,
  }) => _db.assessmentResults.watch(
    (r) =>
        r.tenantId == tenantId &&
        (assessmentId == null || r.assessmentId == assessmentId) &&
        (studentId == null || r.studentId == studentId),
  );

  @override
  Future<Assessment> addAssessment(Assessment assessment) async {
    await _db.delay();
    _db.assessments.insert(assessment);
    return assessment;
  }

  @override
  Future<void> upsertResult(AssessmentResult result) async {
    await _db.delay();
    _db.assessmentResults.upsert(result);
  }
}

class MockLessonRepository implements LessonRepository {
  MockLessonRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<RecordedLesson>> watchByTenant(String tenantId) => _db.lessons.watch(
    (l) => l.tenantId == tenantId,
    sort: (a, b) => b.createdAt.compareTo(a.createdAt),
  );

  @override
  Future<RecordedLesson> add(RecordedLesson lesson) async {
    await _db.delay();
    _db.lessons.insert(lesson);
    return lesson;
  }

  @override
  Future<void> delete(String tenantId, String id) async {
    await _db.delay();
    _db.lessons.removeWhere((l) => l.tenantId == tenantId && l.id == id);
  }
}
