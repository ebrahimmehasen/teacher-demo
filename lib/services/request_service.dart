import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';
import 'notification_service.dart';

abstract final class RequestTypeLabel {
  static String of(RequestType type) => switch (type) {
    RequestType.absence => 'طلب غياب',
    RequestType.changeGroup => 'طلب نقل مجموعة',
    RequestType.other => 'طلب آخر',
  };
}

class RequestService {
  RequestService(this._requests, this._notifier);
  final RequestRepository _requests;
  final ActivityNotifier _notifier;
  static const _uuid = Uuid();

  Future<Request> create({
    required String tenantId,
    required String studentId,
    required String studentName,
    required String fromUserId,
    required UserRole fromRole,
    required RequestType type,
    required String text,
    required DateTime now,
    String? requestedGroupId,
    DateTime? date,
  }) async {
    final request = Request(
      id: _uuid.v4(),
      tenantId: tenantId,
      fromUserId: fromUserId,
      fromRole: fromRole,
      studentId: studentId,
      type: type,
      text: text.trim(),
      requestedGroupId: requestedGroupId,
      date: date,
      createdAt: now,
    );
    await _requests.add(request);
    await _notifier.notifyTeacher(
      tenantId: tenantId,
      type: NotificationType.request,
      title: RequestTypeLabel.of(type),
      body: '$studentName: ${request.text}',
      now: now,
      deepLink: '/teacher/requests',
    );
    return request;
  }
}

final requestServiceProvider = Provider(
  (ref) =>
      RequestService(ref.watch(requestRepositoryProvider), ref.watch(activityNotifierProvider)),
);
