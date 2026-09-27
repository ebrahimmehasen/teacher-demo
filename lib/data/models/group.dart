import 'package:flutter/foundation.dart';

import 'clock_time.dart';
import 'enums.dart';

class GroupSession {
  const GroupSession({
    required this.weekday,
    required this.periodIndex,
    required this.startTime,
    required this.endTime,
  }) : assert(weekday >= DateTime.monday && weekday <= DateTime.sunday);

  factory GroupSession.fromJson(Map<String, dynamic> json) => GroupSession(
    weekday: json['weekday'] as int,
    periodIndex: json['periodIndex'] as int,
    startTime: ClockTime.parse(json['startTime'] as String),
    endTime: ClockTime.parse(json['endTime'] as String),
  );

  /// Same convention as [DateTime.weekday] (Monday = 1 ... Sunday = 7).
  final int weekday;

  /// Zero-based row in the schedule grid.
  final int periodIndex;
  final ClockTime startTime;
  final ClockTime endTime;

  GroupSession copyWith({
    int? weekday,
    int? periodIndex,
    ClockTime? startTime,
    ClockTime? endTime,
  }) => GroupSession(
    weekday: weekday ?? this.weekday,
    periodIndex: periodIndex ?? this.periodIndex,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
  );

  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'periodIndex': periodIndex,
    'startTime': startTime.toJson(),
    'endTime': endTime.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is GroupSession &&
      other.weekday == weekday &&
      other.periodIndex == periodIndex &&
      other.startTime == startTime &&
      other.endTime == endTime;

  @override
  int get hashCode => Object.hash(weekday, periodIndex, startTime, endTime);
}

class Group {
  const Group({
    required this.id,
    required this.tenantId,
    required this.gradeId,
    required this.number,
    required this.type,
    required this.capacity,
    required this.sessions,
    this.price,
    this.address,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'] as String,
    tenantId: json['tenantId'] as String,
    gradeId: json['gradeId'] as String,
    number: json['number'] as int,
    type: GroupType.values.byName(json['type'] as String),
    capacity: json['capacity'] as int,
    price: (json['price'] as num?)?.toDouble(),
    address: json['address'] as String?,
    sessions: [
      for (final s in json['sessions'] as List) GroupSession.fromJson(s as Map<String, dynamic>),
    ],
  );

  final String id;
  final String tenantId;
  final String gradeId;

  /// 1 = المجموعة الأولى, 2 = المجموعة الثانية ...
  final int number;
  final GroupType type;
  final int capacity;

  /// Custom price for private groups; null for public groups (they use the grade price).
  final double? price;

  /// Location, private groups only.
  final String? address;
  final List<GroupSession> sessions;

  bool get isPrivate => type == GroupType.private;

  Group copyWith({
    String? gradeId,
    int? number,
    GroupType? type,
    int? capacity,
    double? price,
    String? address,
    List<GroupSession>? sessions,
  }) => Group(
    id: id,
    tenantId: tenantId,
    gradeId: gradeId ?? this.gradeId,
    number: number ?? this.number,
    type: type ?? this.type,
    capacity: capacity ?? this.capacity,
    price: price ?? this.price,
    address: address ?? this.address,
    sessions: sessions ?? this.sessions,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenantId': tenantId,
    'gradeId': gradeId,
    'number': number,
    'type': type.name,
    'capacity': capacity,
    'price': price,
    'address': address,
    'sessions': [for (final s in sessions) s.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is Group &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.gradeId == gradeId &&
      other.number == number &&
      other.type == type &&
      other.capacity == capacity &&
      other.price == price &&
      other.address == address &&
      listEquals(other.sessions, sessions);

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    gradeId,
    number,
    type,
    capacity,
    price,
    address,
    Object.hashAll(sessions),
  );
}

/// Number of rows (periods) in a tenant's weekly schedule grid.
class SchedulePeriods {
  const SchedulePeriods({required this.tenantId, this.count = 6});

  factory SchedulePeriods.fromJson(Map<String, dynamic> json) =>
      SchedulePeriods(tenantId: json['tenantId'] as String, count: json['count'] as int);

  final String tenantId;
  final int count;

  SchedulePeriods copyWith({int? count}) =>
      SchedulePeriods(tenantId: tenantId, count: count ?? this.count);

  Map<String, dynamic> toJson() => {'tenantId': tenantId, 'count': count};

  @override
  bool operator ==(Object other) =>
      other is SchedulePeriods && other.tenantId == tenantId && other.count == count;

  @override
  int get hashCode => Object.hash(tenantId, count);
}
