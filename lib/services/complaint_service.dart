import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';

class ComplaintService {
  ComplaintService(this._complaints, this._students, this._notifications);
  final ComplaintRepository _complaints;
  final StudentRepository _students;
  final NotificationRepository _notifications;
  static const _uuid = Uuid();

  /// A warning goes to the student themselves; a complaint goes to their parent(s).
  Future<Complaint> send({
    required String tenantId,
    required String studentId,
    required ComplaintKind kind,
    required String text,
    required String byUserId,
    required DateTime now,
  }) async {
    final toRole = kind == ComplaintKind.warning ? UserRole.student : UserRole.parent;
    final complaint = Complaint(
      id: _uuid.v4(),
      tenantId: tenantId,
      studentId: studentId,
      toRole: toRole,
      kind: kind,
      text: text.trim(),
      byUserId: byUserId,
      createdAt: now,
    );
    await _complaints.add(complaint);

    final title = kind == ComplaintKind.warning ? 'تنبيه' : 'شكوى';
    final recipients = <String>[];
    if (toRole == UserRole.student) {
      recipients.add(studentId);
    } else {
      final links = await _students.getLinksForStudent(studentId);
      recipients.addAll(links.map((l) => l.parentUserId));
    }
    await _notifications.addAll([
      for (final userId in recipients)
        AppNotification(
          id: _uuid.v4(),
          userId: userId,
          tenantId: tenantId,
          title: title,
          body: complaint.text,
          type: NotificationType.complaint,
          createdAt: now,
          deepLink: toRole == UserRole.student ? '/student/requests' : '/parent/requests',
        ),
    ]);
    return complaint;
  }
}

final complaintServiceProvider = Provider(
  (ref) => ComplaintService(
    ref.watch(complaintRepositoryProvider),
    ref.watch(studentRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
  ),
);
