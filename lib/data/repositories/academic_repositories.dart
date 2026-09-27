import '../models/models.dart';

abstract interface class GradeRepository {
  Stream<List<Grade>> watchByTenant(String tenantId);
  Future<Grade> add(Grade grade);
  Future<void> update(Grade grade);
  Future<void> delete(String tenantId, String id);
}

abstract interface class GroupRepository {
  Stream<List<Group>> watchByTenant(String tenantId);
  Future<Group?> getById(String tenantId, String id);
  Future<Group> add(Group group);
  Future<void> update(Group group);
  Future<void> delete(String tenantId, String id);

  Stream<SchedulePeriods> watchPeriods(String tenantId);
  Future<void> setPeriods(SchedulePeriods periods);
}

abstract interface class EnrollmentRepository {
  Stream<List<Enrollment>> watchByTenant(String tenantId);

  /// A student's enrollments across all tenants (used by the teacher switcher).
  Stream<List<Enrollment>> watchForStudent(String studentId);
  Future<List<Enrollment>> getForStudent(String studentId);
  Future<Enrollment> add(Enrollment enrollment);
  Future<void> update(Enrollment enrollment);
  Future<void> updateAll(List<Enrollment> enrollments);
}

abstract interface class AttendanceRepository {
  Stream<List<Attendance>> watchByTenant(
    String tenantId, {
    DateTime? from,
    DateTime? to,
    String? studentId,
    String? groupId,
  });
  Future<List<Attendance>> query(
    String tenantId, {
    DateTime? from,
    DateTime? to,
    String? studentId,
    String? groupId,
  });
  Future<Attendance> add(Attendance attendance);
  Future<void> update(Attendance attendance);

  /// Inserts new records and replaces existing ones (matched by id).
  Future<void> upsertAll(List<Attendance> records);
  Future<void> delete(String tenantId, String id);
}

abstract interface class AssessmentRepository {
  Stream<List<Assessment>> watchAssessments(String tenantId);
  Stream<List<AssessmentResult>> watchResults(
    String tenantId, {
    String? assessmentId,
    String? studentId,
  });
  Future<Assessment> addAssessment(Assessment assessment);
  Future<void> upsertResult(AssessmentResult result);
  Future<void> upsertResults(List<AssessmentResult> results);
}

abstract interface class LessonRepository {
  Stream<List<RecordedLesson>> watchByTenant(String tenantId);
  Future<RecordedLesson> add(RecordedLesson lesson);
  Future<void> delete(String tenantId, String id);
}
