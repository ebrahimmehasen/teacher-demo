import '../models/models.dart';

abstract interface class AuthRepository {
  /// Returns the user when the credentials match, otherwise null.
  Future<User?> signIn({required String phone, required String password});
}

abstract interface class UserRepository {
  Future<User?> getById(String id);
  Future<User?> findByPhone(String phone);
  Stream<List<User>> watchByIds(Set<String> ids);
  Future<User> create(User user);
  Future<void> update(User user);
}

abstract interface class TenantRepository {
  Stream<List<Tenant>> watchAll();
  Stream<Tenant?> watchById(String id);
  Future<Tenant?> getById(String id);
  Future<Tenant?> getByOwner(String ownerUserId);
  Future<Tenant> create(Tenant tenant);
  Future<void> update(Tenant tenant);
}

abstract interface class StaffRepository {
  Stream<List<StaffMember>> watchByTenant(String tenantId);

  /// All staff memberships of a user across tenants.
  Future<List<StaffMember>> getForUser(String userId);
  Future<StaffMember> add(StaffMember member);
  Future<void> update(StaffMember member);
  Future<void> remove(String tenantId, String id);
}

abstract interface class StudentRepository {
  Future<StudentProfile?> getProfile(String userId);
  Stream<List<StudentProfile>> watchProfiles(Set<String> userIds);
  Future<StudentProfile?> findByLinkCode(String code);
  Future<StudentProfile> createProfile(StudentProfile profile);

  Stream<List<ParentLink>> watchLinksForParent(String parentUserId);
  Stream<List<ParentLink>> watchLinksForStudents(Set<String> studentUserIds);
  Future<List<ParentLink>> getLinksForParent(String parentUserId);
  Future<List<ParentLink>> getLinksForStudent(String studentUserId);
  Future<List<ParentLink>> getLinksForStudents(Set<String> studentUserIds);
  Future<void> linkParent(ParentLink link);
}
