import 'enums.dart';

class Attendance {
  const Attendance({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.groupId,
    required this.date,
    required this.status,
    required this.method,
    required this.recordedBy,
    this.lateMinutes = 0,
    this.scanTime,
    this.isMakeup = false,
    this.excuseText,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json['id'] as String,
        tenantId: json['tenantId'] as String,
        studentId: json['studentId'] as String,
        groupId: json['groupId'] as String,
        date: DateTime.parse(json['date'] as String),
        status: AttendanceStatus.values.byName(json['status'] as String),
        lateMinutes: json['lateMinutes'] as int,
        scanTime: json['scanTime'] == null ? null : DateTime.parse(json['scanTime'] as String),
        method: AttendanceMethod.values.byName(json['method'] as String),
        isMakeup: json['isMakeup'] as bool,
        excuseText: json['excuseText'] as String?,
        recordedBy: json['recordedBy'] as String,
      );

  final String id;
  final String tenantId;
  final String studentId;
  final String groupId;

  /// Session day (date only, local midnight).
  final DateTime date;
  final AttendanceStatus status;
  final int lateMinutes;
  final DateTime? scanTime;
  final AttendanceMethod method;

  /// True when the student attended a group other than their own.
  final bool isMakeup;
  final String? excuseText;
  final String recordedBy;

  Attendance copyWith({
    AttendanceStatus? status,
    int? lateMinutes,
    DateTime? scanTime,
    AttendanceMethod? method,
    bool? isMakeup,
    String? excuseText,
    String? recordedBy,
  }) =>
      Attendance(
        id: id,
        tenantId: tenantId,
        studentId: studentId,
        groupId: groupId,
        date: date,
        status: status ?? this.status,
        lateMinutes: lateMinutes ?? this.lateMinutes,
        scanTime: scanTime ?? this.scanTime,
        method: method ?? this.method,
        isMakeup: isMakeup ?? this.isMakeup,
        excuseText: excuseText ?? this.excuseText,
        recordedBy: recordedBy ?? this.recordedBy,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'studentId': studentId,
        'groupId': groupId,
        'date': date.toIso8601String(),
        'status': status.name,
        'lateMinutes': lateMinutes,
        'scanTime': scanTime?.toIso8601String(),
        'method': method.name,
        'isMakeup': isMakeup,
        'excuseText': excuseText,
        'recordedBy': recordedBy,
      };

  @override
  bool operator ==(Object other) =>
      other is Attendance &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.studentId == studentId &&
      other.groupId == groupId &&
      other.date == date &&
      other.status == status &&
      other.lateMinutes == lateMinutes &&
      other.scanTime == scanTime &&
      other.method == method &&
      other.isMakeup == isMakeup &&
      other.excuseText == excuseText &&
      other.recordedBy == recordedBy;

  @override
  int get hashCode => Object.hash(id, tenantId, studentId, groupId, date, status, lateMinutes,
      scanTime, method, isMakeup, excuseText, recordedBy);
}
