import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';

class PlatformAdminException implements Exception {
  const PlatformAdminException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PlatformAdminService {
  PlatformAdminService(this._users, this._tenants);
  final UserRepository _users;
  final TenantRepository _tenants;
  static const _uuid = Uuid();

  /// Default password for teacher accounts created here (mock only).
  static const defaultPassword = '123456';

  Future<Tenant> addTeacher({
    required String teacherName,
    required String subject,
    required String phone,
    SubscriptionPlan plan = SubscriptionPlan.basic,
  }) async {
    if (await _users.findByPhone(phone.trim()) != null) {
      throw const PlatformAdminException('رقم الموبايل مسجل بالفعل');
    }
    final owner = await _users.create(
      User(
        id: _uuid.v4(),
        name: teacherName.trim(),
        phone: phone.trim(),
        password: defaultPassword,
        role: UserRole.teacher,
      ),
    );
    return _tenants.create(
      Tenant(
        id: _uuid.v4(),
        ownerUserId: owner.id,
        teacherName: teacherName.trim(),
        subject: subject.trim(),
        phone: phone.trim(),
        subscriptionPlan: plan,
        subscriptionStatus: SubscriptionStatus.trial,
        settings: const TenantSettings(),
      ),
    );
  }

  Future<void> setStatus(Tenant tenant, SubscriptionStatus status) =>
      _tenants.update(tenant.copyWith(subscriptionStatus: status));
}

final platformAdminServiceProvider = Provider(
  (ref) =>
      PlatformAdminService(ref.watch(userRepositoryProvider), ref.watch(tenantRepositoryProvider)),
);

/// Active student count of an arbitrary tenant (platform admin isn't scoped to one).
final tenantStudentCountProvider = StreamProvider.family<int, String>(
  (ref, tenantId) => ref
      .watch(enrollmentRepositoryProvider)
      .watchByTenant(tenantId)
      .map((enrollments) => enrollments.where((e) => e.active).length),
);
