import '../models/models.dart';
import '../repositories/repositories.dart';
import 'mock_database.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._db);
  final MockDatabase _db;

  @override
  Future<User?> signIn({required String phone, required String password}) async {
    await _db.delay();
    return _db.users.firstWhereOrNull((u) => u.phone == phone && u.password == password);
  }
}

class MockUserRepository implements UserRepository {
  MockUserRepository(this._db);
  final MockDatabase _db;

  @override
  Future<User?> getById(String id) async {
    await _db.delay();
    return _db.users.firstWhereOrNull((u) => u.id == id);
  }

  @override
  Future<User?> findByPhone(String phone) async {
    await _db.delay();
    return _db.users.firstWhereOrNull((u) => u.phone == phone);
  }

  @override
  Stream<List<User>> watchByIds(Set<String> ids) =>
      _db.users.watch((u) => ids.contains(u.id), sort: (a, b) => a.name.compareTo(b.name));

  @override
  Future<User> create(User user) async {
    await _db.delay();
    if (_db.users.firstWhereOrNull((u) => u.phone == user.phone) != null) {
      throw StateError('Phone already registered');
    }
    _db.users.insert(user);
    return user;
  }

  @override
  Future<void> update(User user) async {
    await _db.delay();
    _db.users.replace(user);
  }
}

class MockTenantRepository implements TenantRepository {
  MockTenantRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<Tenant>> watchAll() => _db.tenants.watch((_) => true);

  @override
  Stream<Tenant?> watchById(String id) => _db.tenants
      .watch((t) => t.id == id)
      .map((rows) => rows.isEmpty ? null : rows.first);

  @override
  Future<Tenant?> getById(String id) async {
    await _db.delay();
    return _db.tenants.firstWhereOrNull((t) => t.id == id);
  }

  @override
  Future<Tenant?> getByOwner(String ownerUserId) async {
    await _db.delay();
    return _db.tenants.firstWhereOrNull((t) => t.ownerUserId == ownerUserId);
  }

  @override
  Future<Tenant> create(Tenant tenant) async {
    await _db.delay();
    _db.tenants.insert(tenant);
    _db.periods.insert(SchedulePeriods(tenantId: tenant.id));
    return tenant;
  }

  @override
  Future<void> update(Tenant tenant) async {
    await _db.delay();
    _db.tenants.replace(tenant);
  }
}

class MockStaffRepository implements StaffRepository {
  MockStaffRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<StaffMember>> watchByTenant(String tenantId) =>
      _db.staff.watch((s) => s.tenantId == tenantId);

  @override
  Future<List<StaffMember>> getForUser(String userId) async {
    await _db.delay();
    return _db.staff.where((s) => s.userId == userId);
  }

  @override
  Future<StaffMember> add(StaffMember member) async {
    await _db.delay();
    _db.staff.insert(member);
    return member;
  }

  @override
  Future<void> update(StaffMember member) async {
    await _db.delay();
    _db.staff.replace(member);
  }

  @override
  Future<void> remove(String tenantId, String id) async {
    await _db.delay();
    _db.staff.removeWhere((s) => s.tenantId == tenantId && s.id == id);
  }
}

class MockStudentRepository implements StudentRepository {
  MockStudentRepository(this._db);
  final MockDatabase _db;

  @override
  Future<StudentProfile?> getProfile(String userId) async {
    await _db.delay();
    return _db.studentProfiles.firstWhereOrNull((p) => p.userId == userId);
  }

  @override
  Stream<List<StudentProfile>> watchProfiles(Set<String> userIds) =>
      _db.studentProfiles.watch((p) => userIds.contains(p.userId));

  @override
  Future<StudentProfile?> findByLinkCode(String code) async {
    await _db.delay();
    final normalized = code.trim().toUpperCase();
    return _db.studentProfiles.firstWhereOrNull((p) => p.parentLinkCode == normalized);
  }

  @override
  Future<StudentProfile> createProfile(StudentProfile profile) async {
    await _db.delay();
    _db.studentProfiles.insert(profile);
    return profile;
  }

  @override
  Stream<List<ParentLink>> watchLinksForParent(String parentUserId) =>
      _db.parentLinks.watch((l) => l.parentUserId == parentUserId);

  @override
  Stream<List<ParentLink>> watchLinksForStudents(Set<String> studentUserIds) =>
      _db.parentLinks.watch((l) => studentUserIds.contains(l.studentUserId));

  @override
  Future<List<ParentLink>> getLinksForParent(String parentUserId) async {
    await _db.delay();
    return _db.parentLinks.where((l) => l.parentUserId == parentUserId);
  }

  @override
  Future<List<ParentLink>> getLinksForStudent(String studentUserId) async {
    await _db.delay();
    return _db.parentLinks.where((l) => l.studentUserId == studentUserId);
  }

  @override
  Future<void> linkParent(ParentLink link) async {
    await _db.delay();
    _db.parentLinks.upsert(link);
  }
}
