import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';
import 'group_service.dart';

class AdmissionException implements Exception {
  const AdmissionException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AdmissionResult {
  const AdmissionResult({
    required this.student,
    required this.linkCode,
    this.parent,
    this.parentCreated = false,
  });

  final User student;
  final String linkCode;
  final User? parent;
  final bool parentCreated;
}

/// Staff-side student sign-up: creates the student account + profile + enrollment,
/// and optionally creates or links a parent account.
class AdmissionService {
  AdmissionService({
    required this.users,
    required this.students,
    required this.enrollments,
    Random? random,
  }) : _random = random ?? Random.secure();

  final UserRepository users;
  final StudentRepository students;
  final EnrollmentRepository enrollments;
  final Random _random;
  static const _uuid = Uuid();

  /// Default password for accounts created by staff (mock only; shared with the family).
  static const defaultPassword = '123456';
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  Future<String> _uniqueLinkCode() async {
    while (true) {
      final code = String.fromCharCodes(
        List.generate(6, (_) => _codeAlphabet.codeUnitAt(_random.nextInt(_codeAlphabet.length))),
      );
      if (await students.findByLinkCode(code) == null) return code;
    }
  }

  Future<AdmissionResult> admit({
    required String tenantId,
    required String name,
    required String phone,
    required Group group,
    required String schoolYear,
    required List<Enrollment> tenantEnrollments,
    required DateTime now,
    int discountPercent = 0,
    String? parentName,
    String? parentPhone,
  }) async {
    if (!GroupService.hasRoom(group, tenantEnrollments)) {
      throw CapacityException(group);
    }
    if (await users.findByPhone(phone.trim()) != null) {
      throw const AdmissionException('رقم الموبايل مسجل لحساب آخر');
    }
    final parentPhoneTrimmed = parentPhone?.trim() ?? '';
    User? existingParent;
    if (parentPhoneTrimmed.isNotEmpty) {
      if (parentPhoneTrimmed == phone.trim()) {
        throw const AdmissionException('رقم ولي الأمر يجب أن يختلف عن رقم الطالب');
      }
      existingParent = await users.findByPhone(parentPhoneTrimmed);
      if (existingParent != null && existingParent.role != UserRole.parent) {
        throw const AdmissionException('رقم ولي الأمر مسجل لحساب غير ولي أمر');
      }
    }

    final student = await users.create(
      User(
        id: _uuid.v4(),
        name: name.trim(),
        phone: phone.trim(),
        password: defaultPassword,
        role: UserRole.student,
      ),
    );
    final code = await _uniqueLinkCode();
    await students.createProfile(
      StudentProfile(userId: student.id, schoolYear: schoolYear, parentLinkCode: code),
    );
    await enrollments.add(
      Enrollment(
        id: _uuid.v4(),
        tenantId: tenantId,
        studentId: student.id,
        groupId: group.id,
        joinedAt: now,
        discountPercent: discountPercent,
      ),
    );

    if (parentPhoneTrimmed.isEmpty) return AdmissionResult(student: student, linkCode: code);
    final parent =
        existingParent ??
        await users.create(
          User(
            id: _uuid.v4(),
            name: (parentName == null || parentName.trim().isEmpty)
                ? 'ولي أمر ${student.name}'
                : parentName.trim(),
            phone: parentPhoneTrimmed,
            password: defaultPassword,
            role: UserRole.parent,
          ),
        );
    await students.linkParent(ParentLink(parentUserId: parent.id, studentUserId: student.id));
    return AdmissionResult(
      student: student,
      linkCode: code,
      parent: parent,
      parentCreated: existingParent == null,
    );
  }

  /// Links an existing student to a parent (created if the phone is new).
  Future<(User parent, bool created)> linkParent({
    required User student,
    required String parentPhone,
    String? parentName,
  }) async {
    final phone = parentPhone.trim();
    if (phone == student.phone) {
      throw const AdmissionException('رقم ولي الأمر يجب أن يختلف عن رقم الطالب');
    }
    final existing = await users.findByPhone(phone);
    if (existing != null && existing.role != UserRole.parent) {
      throw const AdmissionException('رقم ولي الأمر مسجل لحساب غير ولي أمر');
    }
    final parent =
        existing ??
        await users.create(
          User(
            id: _uuid.v4(),
            name: (parentName == null || parentName.trim().isEmpty)
                ? 'ولي أمر ${student.name}'
                : parentName.trim(),
            phone: phone,
            password: defaultPassword,
            role: UserRole.parent,
          ),
        );
    await students.linkParent(ParentLink(parentUserId: parent.id, studentUserId: student.id));
    return (parent, existing == null);
  }
}

final admissionServiceProvider = Provider(
  (ref) => AdmissionService(
    users: ref.watch(userRepositoryProvider),
    students: ref.watch(studentRepositoryProvider),
    enrollments: ref.watch(enrollmentRepositoryProvider),
  ),
);
