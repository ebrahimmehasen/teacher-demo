import '../data/models/models.dart';

class CapacityException implements Exception {
  const CapacityException(this.group);
  final Group group;

  @override
  String toString() => 'المجموعة مكتملة';
}

abstract final class GroupService {
  static int enrolledCount(String groupId, Iterable<Enrollment> enrollments) =>
      enrollments.where((e) => e.active && e.groupId == groupId).length;

  /// Rule 4: adding/moving students into a full group is blocked.
  static bool hasRoom(Group group, Iterable<Enrollment> enrollments, {int adding = 1}) =>
      enrolledCount(group.id, enrollments) + adding <= group.capacity;

  /// Moves [studentEnrollments] into [target]; throws [CapacityException] if they don't fit.
  static List<Enrollment> moveTo(
    Group target,
    List<Enrollment> studentEnrollments,
    Iterable<Enrollment> allEnrollments,
  ) {
    final incoming = studentEnrollments.where((e) => e.groupId != target.id).toList();
    if (!hasRoom(target, allEnrollments, adding: incoming.length)) {
      throw CapacityException(target);
    }
    return [for (final e in incoming) e.copyWith(groupId: target.id)];
  }

  static int nextNumber(String gradeId, Iterable<Group> groups) {
    final numbers = groups.where((g) => g.gradeId == gradeId).map((g) => g.number);
    return numbers.isEmpty ? 1 : numbers.reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Other groups whose sessions overlap [sessions] in time on the same day.
  static List<Group> conflictingGroups(
    List<GroupSession> sessions,
    Iterable<Group> groups, {
    String? ignoreGroupId,
  }) {
    bool overlaps(GroupSession a, GroupSession b) =>
        a.weekday == b.weekday &&
        a.startTime.compareTo(b.endTime) < 0 &&
        b.startTime.compareTo(a.endTime) < 0;

    return [
      for (final group in groups)
        if (group.id != ignoreGroupId &&
            group.sessions.any((other) => sessions.any((s) => overlaps(s, other))))
          group,
    ];
  }

  static const defaultSessionMinutes = 90;

  /// Start time most used for [periodIndex] by existing groups, else 9:00 + 2h per period.
  static ClockTime defaultStart(int periodIndex, Iterable<Group> groups) {
    final counts = <ClockTime, int>{};
    for (final s in groups.expand((g) => g.sessions)) {
      if (s.periodIndex == periodIndex) counts[s.startTime] = (counts[s.startTime] ?? 0) + 1;
    }
    if (counts.isNotEmpty) {
      return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }
    final hour = 9 + 2 * periodIndex;
    return ClockTime(hour > 21 ? 21 : hour, 0);
  }

  /// Highest period index used by any session, or -1.
  static int maxUsedPeriod(Iterable<Group> groups) =>
      groups.expand((g) => g.sessions).fold(-1, (m, s) => s.periodIndex > m ? s.periodIndex : m);

  /// Sessions of [groups] happening on [day]'s weekday.
  static List<(Group, GroupSession)> sessionsOn(DateTime day, Iterable<Group> groups) => [
    for (final g in groups)
      for (final s in g.sessions)
        if (s.weekday == day.weekday) (g, s),
  ];
}
