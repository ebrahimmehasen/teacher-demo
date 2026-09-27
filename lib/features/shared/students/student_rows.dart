import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/models.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/payment_status_service.dart';
import '../../../services/tenant_data.dart';

class StudentRow {
  const StudentRow({required this.student, required this.billing});

  final User student;
  final Billing billing;

  Enrollment get enrollment => billing.enrollment;
  Group get group => billing.group;
  Grade get grade => billing.grade;
}

class StudentFilter {
  const StudentFilter({this.query = '', this.gradeId, this.groupId, this.status});

  final String query;
  final String? gradeId;
  final String? groupId;
  final PaymentStatus? status;

  bool matches(StudentRow row) {
    final q = query.trim();
    if (q.isNotEmpty && !row.student.name.contains(q) && !row.student.phone.contains(q)) {
      return false;
    }
    if (gradeId != null && row.grade.id != gradeId) return false;
    if (groupId != null && row.group.id != groupId) return false;
    if (status != null && row.billing.status != status) return false;
    return true;
  }
}

final studentRowsProvider = FutureProvider<List<StudentRow>>((ref) async {
  final billing = await ref.watch(currentBillingProvider.future);
  final students = await ref.watch(tenantStudentsProvider.future);
  return [
    for (final b in billing)
      if (students[b.enrollment.studentId] case final student?)
        StudentRow(student: student, billing: b),
  ]..sort((a, b) => a.student.name.compareTo(b.student.name));
});
