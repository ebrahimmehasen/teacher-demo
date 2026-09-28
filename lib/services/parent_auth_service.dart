import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';

class ParentAuthException implements Exception {
  const ParentAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ParentAuthService {
  ParentAuthService(this._users, this._students);
  final UserRepository _users;
  final StudentRepository _students;
  static const _uuid = Uuid();

  Future<User> signUp({
    required String name,
    required String phone,
    required String password,
  }) async {
    if (await _users.findByPhone(phone.trim()) != null) {
      throw const ParentAuthException('رقم الموبايل مسجل بالفعل');
    }
    return _users.create(
      User(
        id: _uuid.v4(),
        name: name.trim(),
        phone: phone.trim(),
        password: password,
        role: UserRole.parent,
      ),
    );
  }

  /// Links a child to [parent] by their unique link code.
  Future<User> linkChildByCode({required User parent, required String code}) async {
    final profile = await _students.findByLinkCode(code.trim());
    if (profile == null) throw const ParentAuthException('كود الربط غير صحيح');
    final existing = await _students.getLinksForParent(parent.id);
    if (existing.any((l) => l.studentUserId == profile.userId)) {
      throw const ParentAuthException('هذا الطالب مرتبط بحسابك بالفعل');
    }
    await _students.linkParent(ParentLink(parentUserId: parent.id, studentUserId: profile.userId));
    final child = await _users.getById(profile.userId);
    if (child == null) throw const ParentAuthException('تعذر العثور على بيانات الطالب');
    return child;
  }
}

final parentAuthServiceProvider = Provider(
  (ref) =>
      ParentAuthService(ref.watch(userRepositoryProvider), ref.watch(studentRepositoryProvider)),
);
