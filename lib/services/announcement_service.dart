import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';

class AnnouncementService {
  AnnouncementService(this._announcements, this._students, this._notifications);
  final AnnouncementRepository _announcements;
  final StudentRepository _students;
  final NotificationRepository _notifications;
  static const _uuid = Uuid();

  /// Rule 9: reaches every student of [targetStudentIds] (all of the tenant,
  /// or one grade) and their parents.
  Future<Announcement> create({
    required String tenantId,
    required String title,
    required String body,
    String? gradeId,
    required Set<String> targetStudentIds,
    required DateTime now,
  }) async {
    final announcement = Announcement(
      id: _uuid.v4(),
      tenantId: tenantId,
      gradeId: gradeId,
      title: title.trim(),
      body: body.trim(),
      createdAt: now,
    );
    await _announcements.add(announcement);

    final links = await _students.getLinksForStudents(targetStudentIds);
    await _notifications.addAll([
      for (final studentId in targetStudentIds)
        AppNotification(
          id: _uuid.v4(),
          userId: studentId,
          tenantId: tenantId,
          title: announcement.title,
          body: announcement.body,
          type: NotificationType.announcement,
          createdAt: now,
          deepLink: '/student/more/announcements',
        ),
      for (final link in links)
        AppNotification(
          id: _uuid.v4(),
          userId: link.parentUserId,
          tenantId: tenantId,
          title: announcement.title,
          body: announcement.body,
          type: NotificationType.announcement,
          createdAt: now,
          deepLink: '/parent/more/announcements',
        ),
    ]);
    return announcement;
  }
}

final announcementServiceProvider = Provider(
  (ref) => AnnouncementService(
    ref.watch(announcementRepositoryProvider),
    ref.watch(studentRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
  ),
);
