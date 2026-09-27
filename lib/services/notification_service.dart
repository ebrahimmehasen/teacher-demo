import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';
import 'session_service.dart';

final myNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final userId = ref.watch(sessionProvider.select((s) => s?.user.id));
  if (userId == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchForUser(userId);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(myNotificationsProvider).asData?.value ?? const [];
  return notifications.where((n) => !n.read).length;
});

/// One event message, phrased per audience.
class EventMessage {
  const EventMessage({
    required this.title,
    required this.forStudent,
    required this.forParent,
    this.forTeacher,
    this.teacherLink,
  });

  final String title;
  final String forStudent;
  final String forParent;

  /// Null skips the teacher.
  final String? forTeacher;
  final String? teacherLink;
}

/// Rule 8: attendance / payment events reach the student, their parents and the teacher.
class ActivityNotifier {
  ActivityNotifier(this._students, this._tenants, this._notifications);

  final StudentRepository _students;
  final TenantRepository _tenants;
  final NotificationRepository _notifications;
  static const _uuid = Uuid();

  Future<void> notifyStudentCircle({
    required String tenantId,
    required String studentId,
    required NotificationType type,
    required EventMessage message,
    required DateTime now,
  }) => notifyStudents(tenantId: tenantId, type: type, now: now, events: [(studentId, message)]);

  /// Batched version: one parent-link lookup for all [events].
  Future<void> notifyStudents({
    required String tenantId,
    required NotificationType type,
    required DateTime now,
    required List<(String studentId, EventMessage message)> events,
  }) async {
    if (events.isEmpty) return;
    final links = await _students.getLinksForStudents({for (final (id, _) in events) id});
    final needsTeacher = events.any((e) => e.$2.forTeacher != null);
    final tenant = needsTeacher ? await _tenants.getById(tenantId) : null;

    AppNotification build(String userId, String title, String body, String? link) =>
        AppNotification(
          id: _uuid.v4(),
          userId: userId,
          tenantId: tenantId,
          title: title,
          body: body,
          type: type,
          createdAt: now,
          deepLink: link,
        );

    await _notifications.addAll([
      for (final (studentId, m) in events) ...[
        build(studentId, m.title, m.forStudent, '/student/home'),
        for (final link in links.where((l) => l.studentUserId == studentId))
          build(link.parentUserId, m.title, m.forParent, '/parent/home'),
        if (tenant != null && m.forTeacher != null)
          build(tenant.ownerUserId, m.title, m.forTeacher!, m.teacherLink),
      ],
    ]);
  }

  /// Sends one notification to the teacher of [tenantId] only.
  Future<void> notifyTeacher({
    required String tenantId,
    required NotificationType type,
    required String title,
    required String body,
    required DateTime now,
    String? deepLink,
  }) async {
    final tenant = await _tenants.getById(tenantId);
    if (tenant == null) return;
    await _notifications.addAll([
      AppNotification(
        id: _uuid.v4(),
        userId: tenant.ownerUserId,
        tenantId: tenantId,
        title: title,
        body: body,
        type: type,
        createdAt: now,
        deepLink: deepLink,
      ),
    ]);
  }
}

final activityNotifierProvider = Provider(
  (ref) => ActivityNotifier(
    ref.watch(studentRepositoryProvider),
    ref.watch(tenantRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
  ),
);
