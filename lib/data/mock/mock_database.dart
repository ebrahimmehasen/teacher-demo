import 'dart:async';
import 'dart:math';

import '../models/models.dart';
import 'seed_data.dart';

/// One in-memory collection that notifies watchers on every write.
class MockTable<T> {
  MockTable(this._idOf, this._latency, [Iterable<T> rows = const []]) : _rows = [...rows];

  final String Function(T row) _idOf;
  final Duration Function() _latency;
  final List<T> _rows;
  final _changes = StreamController<void>.broadcast();

  List<T> get rows => List.unmodifiable(_rows);

  List<T> where(bool Function(T row) test) => _rows.where(test).toList();

  T? firstWhereOrNull(bool Function(T row) test) {
    for (final row in _rows) {
      if (test(row)) return row;
    }
    return null;
  }

  void insert(T row) {
    if (_rows.any((r) => _idOf(r) == _idOf(row))) {
      throw StateError('Duplicate id ${_idOf(row)} in $T table');
    }
    _rows.add(row);
    _changes.add(null);
  }

  void insertAll(Iterable<T> rows) {
    _rows.addAll(rows);
    _changes.add(null);
  }

  void replace(T row) {
    final index = _rows.indexWhere((r) => _idOf(r) == _idOf(row));
    if (index < 0) throw StateError('No $T with id ${_idOf(row)}');
    _rows[index] = row;
    _changes.add(null);
  }

  void upsert(T row) {
    final index = _rows.indexWhere((r) => _idOf(r) == _idOf(row));
    if (index < 0) {
      _rows.add(row);
    } else {
      _rows[index] = row;
    }
    _changes.add(null);
  }

  void updateWhere(bool Function(T row) test, T Function(T row) update) {
    for (var i = 0; i < _rows.length; i++) {
      if (test(_rows[i])) _rows[i] = update(_rows[i]);
    }
    _changes.add(null);
  }

  void removeWhere(bool Function(T row) test) {
    _rows.removeWhere(test);
    _changes.add(null);
  }

  /// Emits the matching rows after a simulated latency, then again after every write.
  Stream<List<T>> watch(bool Function(T row) test, {int Function(T a, T b)? sort}) {
    List<T> snapshot() {
      final result = _rows.where(test).toList();
      if (sort != null) result.sort(sort);
      return result;
    }

    late final StreamController<List<T>> controller;
    StreamSubscription<void>? subscription;
    controller = StreamController<List<T>>(
      onListen: () {
        subscription = _changes.stream.listen((_) => controller.add(snapshot()));
        Future<void>.delayed(_latency(), () {
          if (!controller.isClosed) controller.add(snapshot());
        });
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }
}

/// The single in-memory store shared by all roles during a session.
class MockDatabase {
  MockDatabase(SeedData seed, {Duration Function()? latency})
      : latency = latency ?? _randomLatency {
    tenants = MockTable((r) => r.id, this.latency, seed.tenants);
    users = MockTable((r) => r.id, this.latency, seed.users);
    staff = MockTable((r) => r.id, this.latency, seed.staff);
    studentProfiles = MockTable((r) => r.userId, this.latency, seed.studentProfiles);
    parentLinks = MockTable(
        (r) => '${r.parentUserId}|${r.studentUserId}', this.latency, seed.parentLinks);
    grades = MockTable((r) => r.id, this.latency, seed.grades);
    groups = MockTable((r) => r.id, this.latency, seed.groups);
    periods = MockTable((r) => r.tenantId, this.latency, seed.periods);
    enrollments = MockTable((r) => r.id, this.latency, seed.enrollments);
    attendance = MockTable((r) => r.id, this.latency, seed.attendance);
    payments = MockTable((r) => r.id, this.latency, seed.payments);
    expenses = MockTable((r) => r.id, this.latency, seed.expenses);
    sheets = MockTable((r) => r.id, this.latency, seed.sheets);
    sheetSales = MockTable((r) => r.id, this.latency, seed.sheetSales);
    assessments = MockTable((r) => r.id, this.latency, seed.assessments);
    assessmentResults = MockTable((r) => r.id, this.latency, seed.assessmentResults);
    requests = MockTable((r) => r.id, this.latency, seed.requests);
    complaints = MockTable((r) => r.id, this.latency, seed.complaints);
    announcements = MockTable((r) => r.id, this.latency, seed.announcements);
    lessons = MockTable((r) => r.id, this.latency, seed.lessons);
    notifications = MockTable((r) => r.id, this.latency, seed.notifications);
  }

  static final _latencyRandom = Random();
  static Duration _randomLatency() =>
      Duration(milliseconds: 300 + _latencyRandom.nextInt(301));

  final Duration Function() latency;

  Future<void> delay() => Future<void>.delayed(latency());

  late final MockTable<Tenant> tenants;
  late final MockTable<User> users;
  late final MockTable<StaffMember> staff;
  late final MockTable<StudentProfile> studentProfiles;
  late final MockTable<ParentLink> parentLinks;
  late final MockTable<Grade> grades;
  late final MockTable<Group> groups;
  late final MockTable<SchedulePeriods> periods;
  late final MockTable<Enrollment> enrollments;
  late final MockTable<Attendance> attendance;
  late final MockTable<Payment> payments;
  late final MockTable<Expense> expenses;
  late final MockTable<Sheet> sheets;
  late final MockTable<SheetSale> sheetSales;
  late final MockTable<Assessment> assessments;
  late final MockTable<AssessmentResult> assessmentResults;
  late final MockTable<Request> requests;
  late final MockTable<Complaint> complaints;
  late final MockTable<Announcement> announcements;
  late final MockTable<RecordedLesson> lessons;
  late final MockTable<AppNotification> notifications;
}
