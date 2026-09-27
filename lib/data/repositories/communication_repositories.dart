import '../models/models.dart';

abstract interface class RequestRepository {
  Stream<List<Request>> watchByTenant(String tenantId, {String? studentId});
  Future<Request> add(Request request);
  Future<void> update(Request request);
}

abstract interface class ComplaintRepository {
  Stream<List<Complaint>> watchByTenant(String tenantId, {String? studentId});
  Future<Complaint> add(Complaint complaint);
}

abstract interface class AnnouncementRepository {
  Stream<List<Announcement>> watchByTenant(String tenantId);
  Future<Announcement> add(Announcement announcement);
  Future<void> delete(String tenantId, String id);
}

abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watchForUser(String userId);
  Future<void> addAll(List<AppNotification> notifications);
  Future<void> markRead(String userId, String id);
  Future<void> markAllRead(String userId);
}
