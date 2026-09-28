import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';

class StaffServiceException implements Exception {
  const StaffServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class StaffService {
  StaffService(this._users, this._staff);
  final UserRepository _users;
  final StaffRepository _staff;
  static const _uuid = Uuid();

  /// Default password for staff accounts created here (mock only).
  static const defaultPassword = '123456';

  /// Creates a staff account (or reuses one already registered by that phone)
  /// and adds it to the tenant with the given permissions.
  Future<StaffMember> add({
    required String tenantId,
    required String name,
    required String phone,
    required StaffType type,
    required Set<Permission> permissions,
  }) async {
    final existing = await _users.findByPhone(phone.trim());
    if (existing != null && existing.role != UserRole.assistant) {
      throw const StaffServiceException('رقم الموبايل مسجل لحساب من نوع آخر');
    }
    final memberships = existing == null
        ? const <StaffMember>[]
        : await _staff.getForUser(existing.id);
    if (memberships.any((m) => m.tenantId == tenantId)) {
      throw const StaffServiceException('هذا الرقم مضاف بالفعل ضمن المساعدين');
    }

    final user =
        existing ??
        await _users.create(
          User(
            id: _uuid.v4(),
            name: name.trim(),
            phone: phone.trim(),
            password: defaultPassword,
            role: UserRole.assistant,
          ),
        );
    return _staff.add(
      StaffMember(
        id: _uuid.v4(),
        tenantId: tenantId,
        userId: user.id,
        type: type,
        permissions: permissions,
      ),
    );
  }

  Future<void> updatePermissions(StaffMember member, Set<Permission> permissions) =>
      _staff.update(member.copyWith(permissions: permissions));

  Future<void> remove(StaffMember member) => _staff.remove(member.tenantId, member.id);
}

final staffServiceProvider = Provider(
  (ref) => StaffService(ref.watch(userRepositoryProvider), ref.watch(staffRepositoryProvider)),
);
