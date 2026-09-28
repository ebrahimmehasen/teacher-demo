import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';
import 'group_service.dart';
import 'notification_service.dart';
import 'request_service.dart';

class RequestApprovalService {
  RequestApprovalService(this._requests, this._enrollments, this._notifier);

  final RequestRepository _requests;
  final EnrollmentRepository _enrollments;
  final ActivityNotifier _notifier;

  /// Rule 12: approving a change-group request moves the enrollment,
  /// respecting capacity. Throws [CapacityException] when the group is full.
  Future<void> approve(
    Request request, {
    String? reply,
    required DateTime now,
    Group? targetGroup,
    List<Enrollment>? tenantEnrollments,
  }) async {
    if (request.type == RequestType.changeGroup) {
      final target = targetGroup!;
      final studentEnrollments = tenantEnrollments!.where((e) => e.studentId == request.studentId);
      final moved = GroupService.moveTo(target, studentEnrollments.toList(), tenantEnrollments);
      if (moved.isNotEmpty) await _enrollments.updateAll(moved);
    }
    await _setStatus(request, RequestStatus.approved, reply, now);
  }

  Future<void> reject(Request request, {String? reply, required DateTime now}) =>
      _setStatus(request, RequestStatus.rejected, reply, now);

  Future<void> _setStatus(
    Request request,
    RequestStatus status,
    String? reply,
    DateTime now,
  ) async {
    await _requests.update(request.copyWith(status: status, reply: reply));
    final approved = status == RequestStatus.approved;
    await _notifier.notifyStudentCircle(
      tenantId: request.tenantId,
      studentId: request.studentId,
      type: NotificationType.request,
      now: now,
      message: EventMessage(
        title: approved ? 'تم قبول الطلب' : 'تم رفض الطلب',
        forStudent:
            '${RequestTypeLabel.of(request.type)}: ${approved ? 'تم القبول' : 'تم الرفض'}.'
            '${reply == null ? '' : '\n$reply'}',
        forParent:
            '${RequestTypeLabel.of(request.type)}: ${approved ? 'تم القبول' : 'تم الرفض'}.'
            '${reply == null ? '' : '\n$reply'}',
      ),
    );
  }
}

final requestApprovalServiceProvider = Provider(
  (ref) => RequestApprovalService(
    ref.watch(requestRepositoryProvider),
    ref.watch(enrollmentRepositoryProvider),
    ref.watch(activityNotifierProvider),
  ),
);
