/// A wall-clock time without a date (e.g. a session start time).
class ClockTime implements Comparable<ClockTime> {
  const ClockTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  factory ClockTime.fromMinutes(int minutes) => ClockTime((minutes ~/ 60) % 24, minutes % 60);

  factory ClockTime.parse(String value) {
    final parts = value.split(':');
    return ClockTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int hour;
  final int minute;

  int get inMinutes => hour * 60 + minute;

  DateTime onDate(DateTime date) => DateTime(date.year, date.month, date.day, hour, minute);

  ClockTime addMinutes(int minutes) => ClockTime.fromMinutes(inMinutes + minutes);

  String toJson() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(ClockTime other) => inMinutes.compareTo(other.inMinutes);

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => toJson();
}
