import '../models/models.dart';

/// Plain snapshot of all mock rows produced by the seed generator.
class SeedData {
  const SeedData({
    required this.tenants,
    required this.users,
    required this.staff,
    required this.studentProfiles,
    required this.parentLinks,
    required this.grades,
    required this.groups,
    required this.periods,
    required this.enrollments,
    required this.attendance,
    required this.payments,
    required this.expenses,
    required this.sheets,
    required this.sheetSales,
    required this.assessments,
    required this.assessmentResults,
    required this.requests,
    required this.complaints,
    required this.announcements,
    required this.lessons,
    required this.notifications,
  });

  final List<Tenant> tenants;
  final List<User> users;
  final List<StaffMember> staff;
  final List<StudentProfile> studentProfiles;
  final List<ParentLink> parentLinks;
  final List<Grade> grades;
  final List<Group> groups;
  final List<SchedulePeriods> periods;
  final List<Enrollment> enrollments;
  final List<Attendance> attendance;
  final List<Payment> payments;
  final List<Expense> expenses;
  final List<Sheet> sheets;
  final List<SheetSale> sheetSales;
  final List<Assessment> assessments;
  final List<AssessmentResult> assessmentResults;
  final List<Request> requests;
  final List<Complaint> complaints;
  final List<Announcement> announcements;
  final List<RecordedLesson> lessons;
  final List<AppNotification> notifications;

  Map<String, List<Map<String, dynamic>>> toJson() => {
    'tenants': [for (final r in tenants) r.toJson()],
    'users': [for (final r in users) r.toJson()],
    'staff': [for (final r in staff) r.toJson()],
    'studentProfiles': [for (final r in studentProfiles) r.toJson()],
    'parentLinks': [for (final r in parentLinks) r.toJson()],
    'grades': [for (final r in grades) r.toJson()],
    'groups': [for (final r in groups) r.toJson()],
    'periods': [for (final r in periods) r.toJson()],
    'enrollments': [for (final r in enrollments) r.toJson()],
    'attendance': [for (final r in attendance) r.toJson()],
    'payments': [for (final r in payments) r.toJson()],
    'expenses': [for (final r in expenses) r.toJson()],
    'sheets': [for (final r in sheets) r.toJson()],
    'sheetSales': [for (final r in sheetSales) r.toJson()],
    'assessments': [for (final r in assessments) r.toJson()],
    'assessmentResults': [for (final r in assessmentResults) r.toJson()],
    'requests': [for (final r in requests) r.toJson()],
    'complaints': [for (final r in complaints) r.toJson()],
    'announcements': [for (final r in announcements) r.toJson()],
    'lessons': [for (final r in lessons) r.toJson()],
    'notifications': [for (final r in notifications) r.toJson()],
  };
}
