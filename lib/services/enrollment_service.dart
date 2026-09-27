import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';
import 'group_service.dart';

/// Bulk actions on enrollments (exempt, discount, move group).
class EnrollmentActions {
  const EnrollmentActions(this._repo);
  final EnrollmentRepository _repo;

  Future<void> setExempt(List<Enrollment> enrollments, {required bool exempt}) =>
      _repo.updateAll([for (final e in enrollments) e.copyWith(isExempt: exempt)]);

  Future<void> setDiscount(List<Enrollment> enrollments, int percent) =>
      _repo.updateAll([for (final e in enrollments) e.copyWith(discountPercent: percent)]);

  /// Throws [CapacityException] when [target] cannot take them all.
  Future<void> moveTo(
    Group target,
    List<Enrollment> enrollments,
    Iterable<Enrollment> allEnrollments,
  ) async {
    final moved = GroupService.moveTo(target, enrollments, allEnrollments);
    if (moved.isNotEmpty) await _repo.updateAll(moved);
  }
}

final enrollmentActionsProvider = Provider(
  (ref) => EnrollmentActions(ref.watch(enrollmentRepositoryProvider)),
);
