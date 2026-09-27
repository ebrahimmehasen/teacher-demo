import 'enums.dart';

/// A request sent by a student or parent to the teacher (absence, group change...).
class Request {
  const Request({
    required this.id,
    required this.tenantId,
    required this.fromUserId,
    required this.fromRole,
    required this.studentId,
    required this.type,
    required this.text,
    required this.createdAt,
    this.status = RequestStatus.pending,
    this.requestedGroupId,
    this.date,
    this.reply,
  });

  factory Request.fromJson(Map<String, dynamic> json) => Request(
        id: json['id'] as String,
        tenantId: json['tenantId'] as String,
        fromUserId: json['fromUserId'] as String,
        fromRole: UserRole.values.byName(json['fromRole'] as String),
        studentId: json['studentId'] as String,
        type: RequestType.values.byName(json['type'] as String),
        text: json['text'] as String,
        requestedGroupId: json['requestedGroupId'] as String?,
        date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
        status: RequestStatus.values.byName(json['status'] as String),
        reply: json['reply'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String tenantId;
  final String fromUserId;
  final UserRole fromRole;

  /// The student the request is about (the sender itself, or the parent's child).
  final String studentId;
  final RequestType type;
  final String text;
  final String? requestedGroupId;

  /// The day concerned (e.g. absence day).
  final DateTime? date;
  final RequestStatus status;
  final String? reply;
  final DateTime createdAt;

  Request copyWith({RequestStatus? status, String? reply}) => Request(
        id: id,
        tenantId: tenantId,
        fromUserId: fromUserId,
        fromRole: fromRole,
        studentId: studentId,
        type: type,
        text: text,
        requestedGroupId: requestedGroupId,
        date: date,
        status: status ?? this.status,
        reply: reply ?? this.reply,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'fromUserId': fromUserId,
        'fromRole': fromRole.name,
        'studentId': studentId,
        'type': type.name,
        'text': text,
        'requestedGroupId': requestedGroupId,
        'date': date?.toIso8601String(),
        'status': status.name,
        'reply': reply,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is Request &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.fromUserId == fromUserId &&
      other.fromRole == fromRole &&
      other.studentId == studentId &&
      other.type == type &&
      other.text == text &&
      other.requestedGroupId == requestedGroupId &&
      other.date == date &&
      other.status == status &&
      other.reply == reply &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, tenantId, fromUserId, fromRole, studentId, type, text,
      requestedGroupId, date, status, reply, createdAt);
}

/// A complaint sent to a parent, or a warning sent to a student, by the teacher/staff.
class Complaint {
  const Complaint({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.toRole,
    required this.kind,
    required this.text,
    required this.byUserId,
    required this.createdAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
        id: json['id'] as String,
        tenantId: json['tenantId'] as String,
        studentId: json['studentId'] as String,
        toRole: UserRole.values.byName(json['toRole'] as String),
        kind: ComplaintKind.values.byName(json['kind'] as String),
        text: json['text'] as String,
        byUserId: json['byUserId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String tenantId;
  final String studentId;

  /// [UserRole.parent] or [UserRole.student].
  final UserRole toRole;
  final ComplaintKind kind;
  final String text;
  final String byUserId;
  final DateTime createdAt;

  Complaint copyWith({String? text}) => Complaint(
        id: id,
        tenantId: tenantId,
        studentId: studentId,
        toRole: toRole,
        kind: kind,
        text: text ?? this.text,
        byUserId: byUserId,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'studentId': studentId,
        'toRole': toRole.name,
        'kind': kind.name,
        'text': text,
        'byUserId': byUserId,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is Complaint &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.studentId == studentId &&
      other.toRole == toRole &&
      other.kind == kind &&
      other.text == text &&
      other.byUserId == byUserId &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, tenantId, studentId, toRole, kind, text, byUserId, createdAt);
}

class Announcement {
  const Announcement({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.gradeId,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        tenantId: json['tenantId'] as String,
        gradeId: json['gradeId'] as String?,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String tenantId;

  /// Target grade; null means all students of the tenant.
  final String? gradeId;
  final String title;
  final String body;
  final DateTime createdAt;

  bool get isForAll => gradeId == null;

  Announcement copyWith({String? gradeId, String? title, String? body}) => Announcement(
        id: id,
        tenantId: tenantId,
        gradeId: gradeId ?? this.gradeId,
        title: title ?? this.title,
        body: body ?? this.body,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'gradeId': gradeId,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is Announcement &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.gradeId == gradeId &&
      other.title == title &&
      other.body == body &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, tenantId, gradeId, title, body, createdAt);
}

class RecordedLesson {
  const RecordedLesson({
    required this.id,
    required this.tenantId,
    required this.gradeId,
    required this.title,
    required this.driveUrl,
    required this.createdAt,
  });

  factory RecordedLesson.fromJson(Map<String, dynamic> json) => RecordedLesson(
        id: json['id'] as String,
        tenantId: json['tenantId'] as String,
        gradeId: json['gradeId'] as String,
        title: json['title'] as String,
        driveUrl: json['driveUrl'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String tenantId;
  final String gradeId;
  final String title;
  final String driveUrl;
  final DateTime createdAt;

  RecordedLesson copyWith({String? gradeId, String? title, String? driveUrl}) =>
      RecordedLesson(
        id: id,
        tenantId: tenantId,
        gradeId: gradeId ?? this.gradeId,
        title: title ?? this.title,
        driveUrl: driveUrl ?? this.driveUrl,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'gradeId': gradeId,
        'title': title,
        'driveUrl': driveUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is RecordedLesson &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.gradeId == gradeId &&
      other.title == title &&
      other.driveUrl == driveUrl &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, tenantId, gradeId, title, driveUrl, createdAt);
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.tenantId,
    this.read = false,
    this.deepLink,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        userId: json['userId'] as String,
        tenantId: json['tenantId'] as String?,
        title: json['title'] as String,
        body: json['body'] as String,
        type: NotificationType.values.byName(json['type'] as String),
        read: json['read'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        deepLink: json['deepLink'] as String?,
      );

  final String id;
  final String userId;
  final String? tenantId;
  final String title;
  final String body;
  final NotificationType type;
  final bool read;
  final DateTime createdAt;

  /// go_router location to open when the notification is tapped.
  final String? deepLink;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        userId: userId,
        tenantId: tenantId,
        title: title,
        body: body,
        type: type,
        read: read ?? this.read,
        createdAt: createdAt,
        deepLink: deepLink,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'tenantId': tenantId,
        'title': title,
        'body': body,
        'type': type.name,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
        'deepLink': deepLink,
      };

  @override
  bool operator ==(Object other) =>
      other is AppNotification &&
      other.id == id &&
      other.userId == userId &&
      other.tenantId == tenantId &&
      other.title == title &&
      other.body == body &&
      other.type == type &&
      other.read == read &&
      other.createdAt == createdAt &&
      other.deepLink == deepLink;

  @override
  int get hashCode =>
      Object.hash(id, userId, tenantId, title, body, type, read, createdAt, deepLink);
}
