import '../models/models.dart';
import '../repositories/repositories.dart';
import 'mock_database.dart';

class MockRequestRepository implements RequestRepository {
  MockRequestRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<Request>> watchByTenant(String tenantId, {String? studentId}) =>
      _db.requests.watch(
        (r) => r.tenantId == tenantId && (studentId == null || r.studentId == studentId),
        sort: (a, b) => b.createdAt.compareTo(a.createdAt),
      );

  @override
  Future<Request> add(Request request) async {
    await _db.delay();
    _db.requests.insert(request);
    return request;
  }

  @override
  Future<void> update(Request request) async {
    await _db.delay();
    _db.requests.replace(request);
  }
}

class MockComplaintRepository implements ComplaintRepository {
  MockComplaintRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<Complaint>> watchByTenant(String tenantId, {String? studentId}) =>
      _db.complaints.watch(
        (c) => c.tenantId == tenantId && (studentId == null || c.studentId == studentId),
        sort: (a, b) => b.createdAt.compareTo(a.createdAt),
      );

  @override
  Future<Complaint> add(Complaint complaint) async {
    await _db.delay();
    _db.complaints.insert(complaint);
    return complaint;
  }
}

class MockAnnouncementRepository implements AnnouncementRepository {
  MockAnnouncementRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<Announcement>> watchByTenant(String tenantId) => _db.announcements.watch(
        (a) => a.tenantId == tenantId,
        sort: (a, b) => b.createdAt.compareTo(a.createdAt),
      );

  @override
  Future<Announcement> add(Announcement announcement) async {
    await _db.delay();
    _db.announcements.insert(announcement);
    return announcement;
  }

  @override
  Future<void> delete(String tenantId, String id) async {
    await _db.delay();
    _db.announcements.removeWhere((a) => a.tenantId == tenantId && a.id == id);
  }
}

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<AppNotification>> watchForUser(String userId) => _db.notifications.watch(
        (n) => n.userId == userId,
        sort: (a, b) => b.createdAt.compareTo(a.createdAt),
      );

  @override
  Future<void> addAll(List<AppNotification> notifications) async {
    await _db.delay();
    _db.notifications.insertAll(notifications);
  }

  @override
  Future<void> markRead(String userId, String id) async {
    await _db.delay();
    _db.notifications.updateWhere(
      (n) => n.userId == userId && n.id == id,
      (n) => n.copyWith(read: true),
    );
  }

  @override
  Future<void> markAllRead(String userId) async {
    await _db.delay();
    _db.notifications.updateWhere(
      (n) => n.userId == userId && !n.read,
      (n) => n.copyWith(read: true),
    );
  }
}
