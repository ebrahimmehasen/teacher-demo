/// Global student data (not tenant-scoped), attached to a [User] with role student.
class StudentProfile {
  const StudentProfile({
    required this.userId,
    required this.schoolYear,
    required this.parentLinkCode,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        userId: json['userId'] as String,
        schoolYear: json['schoolYear'] as String,
        parentLinkCode: json['parentLinkCode'] as String,
      );

  final String userId;
  final String schoolYear;

  /// Unique 6-char code a parent uses to link this child to their account.
  final String parentLinkCode;

  StudentProfile copyWith({String? schoolYear, String? parentLinkCode}) => StudentProfile(
        userId: userId,
        schoolYear: schoolYear ?? this.schoolYear,
        parentLinkCode: parentLinkCode ?? this.parentLinkCode,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'schoolYear': schoolYear,
        'parentLinkCode': parentLinkCode,
      };

  @override
  bool operator ==(Object other) =>
      other is StudentProfile &&
      other.userId == userId &&
      other.schoolYear == schoolYear &&
      other.parentLinkCode == parentLinkCode;

  @override
  int get hashCode => Object.hash(userId, schoolYear, parentLinkCode);
}

class ParentLink {
  const ParentLink({required this.parentUserId, required this.studentUserId});

  factory ParentLink.fromJson(Map<String, dynamic> json) => ParentLink(
        parentUserId: json['parentUserId'] as String,
        studentUserId: json['studentUserId'] as String,
      );

  final String parentUserId;
  final String studentUserId;

  Map<String, dynamic> toJson() => {
        'parentUserId': parentUserId,
        'studentUserId': studentUserId,
      };

  @override
  bool operator ==(Object other) =>
      other is ParentLink &&
      other.parentUserId == parentUserId &&
      other.studentUserId == studentUserId;

  @override
  int get hashCode => Object.hash(parentUserId, studentUserId);
}

/// A student joining a teacher (tenant) in a specific group.
class Enrollment {
  const Enrollment({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.groupId,
    required this.joinedAt,
    this.isExempt = false,
    this.discountPercent = 0,
    this.active = true,
  }) : assert(discountPercent >= 0 && discountPercent <= 100);

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
        id: json['id'] as String,
        tenantId: json['tenantId'] as String,
        studentId: json['studentId'] as String,
        groupId: json['groupId'] as String,
        isExempt: json['isExempt'] as bool,
        discountPercent: json['discountPercent'] as int,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        active: json['active'] as bool,
      );

  final String id;
  final String tenantId;
  final String studentId;
  final String groupId;
  final bool isExempt;
  final int discountPercent;
  final DateTime joinedAt;
  final bool active;

  Enrollment copyWith({
    String? groupId,
    bool? isExempt,
    int? discountPercent,
    bool? active,
  }) =>
      Enrollment(
        id: id,
        tenantId: tenantId,
        studentId: studentId,
        groupId: groupId ?? this.groupId,
        isExempt: isExempt ?? this.isExempt,
        discountPercent: discountPercent ?? this.discountPercent,
        joinedAt: joinedAt,
        active: active ?? this.active,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'studentId': studentId,
        'groupId': groupId,
        'isExempt': isExempt,
        'discountPercent': discountPercent,
        'joinedAt': joinedAt.toIso8601String(),
        'active': active,
      };

  @override
  bool operator ==(Object other) =>
      other is Enrollment &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.studentId == studentId &&
      other.groupId == groupId &&
      other.isExempt == isExempt &&
      other.discountPercent == discountPercent &&
      other.joinedAt == joinedAt &&
      other.active == active;

  @override
  int get hashCode => Object.hash(
      id, tenantId, studentId, groupId, isExempt, discountPercent, joinedAt, active);
}
