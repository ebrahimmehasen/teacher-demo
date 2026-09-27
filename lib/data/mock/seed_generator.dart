import 'dart:math';

import '../../core/constants/demo_accounts.dart';
import '../../core/utils/date_utils.dart';
import '../../services/pricing_service.dart';
import '../models/models.dart';
import 'seed_data.dart';

/// Builds the deterministic demo dataset. Same [now] ⇒ identical output.
class SeedGenerator {
  SeedGenerator({DateTime? now}) : now = now ?? DateTime.now(), _r = Random(42);

  final DateTime now;
  final Random _r;

  static const mainTenantId = 't-ahmed';
  static const secondTenantId = 't-mona';
  static const mainStudentCount = 60;
  static const parentCount = 50;
  static const _secondTenantExtraStudents = 11;

  static const _periodStarts = [
    ClockTime(9, 0),
    ClockTime(11, 0),
    ClockTime(13, 0),
    ClockTime(15, 0),
    ClockTime(17, 0),
    ClockTime(19, 0),
  ];
  static const _sessionMinutes = 90;

  static const _maleNames = [
    'محمد',
    'أحمد',
    'محمود',
    'مصطفى',
    'عمر',
    'يوسف',
    'علي',
    'حسن',
    'خالد',
    'إبراهيم',
    'كريم',
    'عبدالرحمن',
    'زياد',
    'مازن',
    'آدم',
    'سيف',
    'ياسين',
    'مروان',
    'أنس',
    'حمزة',
  ];
  static const _femaleNames = [
    'مريم',
    'سارة',
    'نور',
    'فاطمة',
    'آية',
    'ملك',
    'جنى',
    'حبيبة',
    'رنا',
    'سلمى',
    'ندى',
    'هنا',
    'ياسمين',
    'دينا',
    'روان',
    'لجين',
    'شهد',
    'منة',
    'رحمة',
    'بسمة',
  ];
  static const _fatherNames = [
    'سامح',
    'طارق',
    'أشرف',
    'هشام',
    'وائل',
    'عادل',
    'ممدوح',
    'شريف',
    'حسام',
    'ماجد',
    'عصام',
    'جمال',
    'رامي',
    'تامر',
    'أيمن',
    'ياسر',
    'نبيل',
    'عماد',
    'سمير',
    'فتحي',
  ];
  static const _familyNames = [
    'عبدالله',
    'السيد',
    'حسين',
    'إبراهيم',
    'مصطفى',
    'عبدالعزيز',
    'الشافعي',
    'منصور',
    'النجار',
    'فهمي',
    'رشدي',
    'سليمان',
    'البنا',
    'زكي',
    'عثمان',
    'الجمال',
    'حجازي',
    'شاكر',
    'بدوي',
    'رضوان',
  ];
  static const _excuses = ['ظروف مرضية', 'مناسبة عائلية', 'امتحان في المدرسة', 'سفر مع الأسرة'];

  // Collections filled by generate().
  final _tenants = <Tenant>[];
  final _users = <User>[];
  final _staff = <StaffMember>[];
  final _profiles = <StudentProfile>[];
  final _links = <ParentLink>[];
  final _grades = <Grade>[];
  final _groups = <Group>[];
  final _periods = <SchedulePeriods>[];
  final _enrollments = <Enrollment>[];
  final _attendance = <Attendance>[];
  final _payments = <Payment>[];
  final _expenses = <Expense>[];
  final _sheets = <Sheet>[];
  final _sales = <SheetSale>[];
  final _assessments = <Assessment>[];
  final _results = <AssessmentResult>[];
  final _requests = <Request>[];
  final _complaints = <Complaint>[];
  final _announcements = <Announcement>[];
  final _lessons = <RecordedLesson>[];
  final _notifications = <AppNotification>[];
  final _usedLinkCodes = <String>{};
  var _seq = 0;

  late final DateTime _today = AppDates.dateOnly(now);

  String _id(String prefix) => '$prefix-${++_seq}';

  static String studentUserId(int index) => 'u-student-$index';
  static String parentUserId(int index) => 'u-parent-$index';
  static const teacherUserId = 'u-teacher-ahmed';
  static const secondTeacherUserId = 'u-teacher-mona';
  static const assistantUserId = 'u-assistant-1';
  static const limitedAssistantUserId = 'u-assistant-2';
  static const platformAdminUserId = 'u-admin';

  SeedData generate() {
    _createAccounts();
    _createMainTenant();
    _createSecondTenant();
    for (final tenant in _tenants) {
      _generateAttendance(tenant);
      _generatePayments(tenant);
    }
    _createMakeupAttendance();
    _createSheets();
    _createAssessments();
    _createCommunication();
    _createExpenses();
    _createNotifications();

    return SeedData(
      tenants: _tenants,
      users: _users,
      staff: _staff,
      studentProfiles: _profiles,
      parentLinks: _links,
      grades: _grades,
      groups: _groups,
      periods: _periods,
      enrollments: _enrollments,
      attendance: _attendance,
      payments: _payments,
      expenses: _expenses,
      sheets: _sheets,
      sheetSales: _sales,
      assessments: _assessments,
      assessmentResults: _results,
      requests: _requests,
      complaints: _complaints,
      announcements: _announcements,
      lessons: _lessons,
      notifications: _notifications,
    );
  }

  // ---------------------------------------------------------------------------
  // Accounts

  void _createAccounts() {
    _users.addAll([
      const User(
        id: platformAdminUserId,
        name: 'إدارة المنصة',
        phone: DemoAccounts.platformAdminPhone,
        password: DemoAccounts.password,
        role: UserRole.platformAdmin,
      ),
      const User(
        id: teacherUserId,
        name: 'أحمد سامي',
        phone: DemoAccounts.teacherPhone,
        password: DemoAccounts.password,
        role: UserRole.teacher,
      ),
      const User(
        id: secondTeacherUserId,
        name: 'منى عادل',
        phone: DemoAccounts.secondTeacherPhone,
        password: DemoAccounts.password,
        role: UserRole.teacher,
      ),
      const User(
        id: assistantUserId,
        name: 'محمود حسن',
        phone: DemoAccounts.assistantPhone,
        password: DemoAccounts.password,
        role: UserRole.assistant,
      ),
      const User(
        id: limitedAssistantUserId,
        name: 'سارة علي',
        phone: DemoAccounts.limitedAssistantPhone,
        password: DemoAccounts.password,
        role: UserRole.assistant,
      ),
    ]);

    // Parent i is the father of student i; parent 0 also has student 50 (two children).
    final fatherOf = <int, String>{};
    final familyOf = <int, String>{};
    for (var i = 0; i < parentCount; i++) {
      fatherOf[i] = _pick(_fatherNames);
      familyOf[i] = _pick(_familyNames);
      _users.add(
        User(
          id: parentUserId(i),
          name: '${fatherOf[i]} ${familyOf[i]}',
          phone: _phone('015', i),
          password: DemoAccounts.password,
          role: UserRole.parent,
        ),
      );
    }

    const totalStudents = mainStudentCount + _secondTenantExtraStudents;
    for (var i = 0; i < totalStudents; i++) {
      final parentIndex = i == 50 ? 0 : (i < parentCount ? i : null);
      final father = parentIndex != null ? fatherOf[parentIndex]! : _pick(_fatherNames);
      final family = parentIndex != null ? familyOf[parentIndex]! : _pick(_familyNames);
      final first = i.isEven ? _pick(_maleNames) : _pick(_femaleNames);
      _users.add(
        User(
          id: studentUserId(i),
          name: '$first $father $family',
          phone: _phone('012', i),
          password: DemoAccounts.password,
          role: UserRole.student,
        ),
      );
      if (parentIndex != null) {
        _links.add(
          ParentLink(parentUserId: parentUserId(parentIndex), studentUserId: studentUserId(i)),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Tenants, grades, groups, enrollments

  void _createMainTenant() {
    _tenants.add(
      const Tenant(
        id: mainTenantId,
        ownerUserId: teacherUserId,
        teacherName: 'أ. أحمد سامي',
        subject: 'فيزياء',
        phone: DemoAccounts.teacherPhone,
        subscriptionPlan: SubscriptionPlan.pro,
        subscriptionStatus: SubscriptionStatus.active,
        settings: TenantSettings(
          acceptedPaymentMethods: {
            PaymentMethod.cash,
            PaymentMethod.vodafoneCash,
            PaymentMethod.instaPay,
          },
          walletNumbers: {
            PaymentMethod.vodafoneCash: '01012345678',
            PaymentMethod.instaPay: 'ahmed.samy@instapay',
          },
        ),
      ),
    );
    _periods.add(const SchedulePeriods(tenantId: mainTenantId));
    _staff.addAll([
      const StaffMember(
        id: 'staff-1',
        tenantId: mainTenantId,
        userId: assistantUserId,
        type: StaffType.assistant,
        permissions: {...Permission.values},
      ),
      const StaffMember(
        id: 'staff-2',
        tenantId: mainTenantId,
        userId: limitedAssistantUserId,
        type: StaffType.supervisor,
        permissions: {Permission.attendance, Permission.sheets},
      ),
    ]);

    final g1 = _grade(mainTenantId, 'g-a-1', 'أولى ثانوي', 250);
    final g2 = _grade(mainTenantId, 'g-a-2', 'تانية ثانوي', 300);
    final g3 = _grade(mainTenantId, 'g-a-3', 'تالتة ثانوي', 350);

    const sat = DateTime.saturday, sun = DateTime.sunday, mon = DateTime.monday;
    const tue = DateTime.tuesday, wed = DateTime.wednesday, thu = DateTime.thursday;

    // Students are assigned in this order; student 0 (demo) lands in grp-a-6,
    // student 50 (demo parent's second child) in grp-a-2, grp-a-8 ends up full.
    final plan = <(Group, int)>[
      (_group(mainTenantId, 'grp-a-6', g3, 1, [(sat, 4), (tue, 4)]), 9),
      (_group(mainTenantId, 'grp-a-7', g3, 2, [(sun, 5), (wed, 5)]), 8),
      (
        _group(
          mainTenantId,
          'grp-a-8',
          g3,
          3,
          [(mon, 5), (thu, 5)],
          price: 800,
          capacity: 5,
          address: 'مدينة نصر – شارع عباس العقاد',
        ),
        5,
      ),
      (_group(mainTenantId, 'grp-a-4', g2, 1, [(sat, 2), (tue, 2)]), 9),
      (_group(mainTenantId, 'grp-a-5', g2, 2, [(sun, 3), (wed, 3)]), 8),
      (_group(mainTenantId, 'grp-a-1', g1, 1, [(sat, 0), (tue, 0)]), 8),
      (_group(mainTenantId, 'grp-a-2', g1, 2, [(sun, 1), (wed, 1)]), 8),
      (
        _group(
          mainTenantId,
          'grp-a-3',
          g1,
          3,
          [(mon, 4), (thu, 4)],
          price: 600,
          capacity: 6,
          address: 'المعادي – شارع 9',
        ),
        5,
      ),
    ];

    var studentIndex = 0;
    for (final (group, count) in plan) {
      final grade = _grades.firstWhere((g) => g.id == group.gradeId);
      for (var k = 0; k < count; k++) {
        _enroll(mainTenantId, studentIndex, group, grade);
        studentIndex++;
      }
    }
    assert(studentIndex == mainStudentCount);

    // Pricing variety: one exempt student and two discounts.
    _updateEnrollment(mainTenantId, 25, (e) => e.copyWith(isExempt: true));
    _updateEnrollment(mainTenantId, 30, (e) => e.copyWith(discountPercent: 20));
    _updateEnrollment(mainTenantId, 40, (e) => e.copyWith(discountPercent: 25));
  }

  void _createSecondTenant() {
    _tenants.add(
      const Tenant(
        id: secondTenantId,
        ownerUserId: secondTeacherUserId,
        teacherName: 'أ. منى عادل',
        subject: 'كيمياء',
        phone: DemoAccounts.secondTeacherPhone,
        subscriptionPlan: SubscriptionPlan.basic,
        subscriptionStatus: SubscriptionStatus.trial,
        settings: TenantSettings(
          acceptedPaymentMethods: {PaymentMethod.cash, PaymentMethod.vodafoneCash},
          walletNumbers: {PaymentMethod.vodafoneCash: '01098765432'},
        ),
      ),
    );
    _periods.add(const SchedulePeriods(tenantId: secondTenantId));

    final grade = _grade(secondTenantId, 'g-m-3', 'تالتة ثانوي', 320);
    final m1 = _group(secondTenantId, 'grp-m-1', grade, 1, [
      (DateTime.monday, 1),
      (DateTime.thursday, 1),
    ]);
    final m2 = _group(secondTenantId, 'grp-m-2', grade, 2, [
      (DateTime.sunday, 2),
      (DateTime.wednesday, 2),
    ], capacity: 25);

    // The demo student studies chemistry too (drives the teacher switcher).
    _enroll(secondTenantId, 0, m1, grade);
    for (var k = 0; k < _secondTenantExtraStudents; k++) {
      _enroll(secondTenantId, mainStudentCount + k, k.isEven ? m1 : m2, grade);
    }
  }

  Grade _grade(String tenantId, String id, String name, double price) {
    final grade = Grade(
      id: id,
      tenantId: tenantId,
      name: name,
      publicPrice: price,
      dueDay: 5,
      graceDays: 5,
      defaultCapacity: 30,
    );
    _grades.add(grade);
    return grade;
  }

  Group _group(
    String tenantId,
    String id,
    Grade grade,
    int number,
    List<(int weekday, int period)> slots, {
    double? price,
    int? capacity,
    String? address,
  }) {
    final group = Group(
      id: id,
      tenantId: tenantId,
      gradeId: grade.id,
      number: number,
      type: price == null ? GroupType.public : GroupType.private,
      capacity: capacity ?? grade.defaultCapacity,
      price: price,
      address: address,
      sessions: [
        for (final (weekday, period) in slots)
          GroupSession(
            weekday: weekday,
            periodIndex: period,
            startTime: _periodStarts[period],
            endTime: _periodStarts[period].addMinutes(_sessionMinutes),
          ),
      ],
    );
    _groups.add(group);
    return group;
  }

  void _enroll(String tenantId, int studentIndex, Group group, Grade grade) {
    final userId = studentUserId(studentIndex);
    if (!_profiles.any((p) => p.userId == userId)) {
      _profiles.add(
        StudentProfile(userId: userId, schoolYear: grade.name, parentLinkCode: _linkCode()),
      );
    }
    _enrollments.add(
      Enrollment(
        id: _id('enr'),
        tenantId: tenantId,
        studentId: userId,
        groupId: group.id,
        joinedAt: _today.subtract(Duration(days: 190 + _r.nextInt(60))),
      ),
    );
  }

  void _updateEnrollment(String tenantId, int studentIndex, Enrollment Function(Enrollment) f) {
    final i = _enrollments.indexWhere(
      (e) => e.tenantId == tenantId && e.studentId == studentUserId(studentIndex),
    );
    _enrollments[i] = f(_enrollments[i]);
  }

  // ---------------------------------------------------------------------------
  // Attendance: every session day of the last 60 days, up to yesterday.

  void _generateAttendance(Tenant tenant) {
    final recorder = tenant.id == mainTenantId ? assistantUserId : secondTeacherUserId;
    final threshold = tenant.settings.lateThresholdMinutes;
    final groups = _groups.where((g) => g.tenantId == tenant.id).toList();
    final reliability = <String, double>{};

    for (var back = 60; back >= 1; back--) {
      final day = _today.subtract(Duration(days: back));
      for (final group in groups) {
        for (final session in group.sessions.where((s) => s.weekday == day.weekday)) {
          final enrolled = _enrollments.where(
            (e) => e.tenantId == tenant.id && e.groupId == group.id && !e.joinedAt.isAfter(day),
          );
          for (final enrollment in enrolled) {
            final risk = reliability.putIfAbsent(
              enrollment.studentId,
              () => _r.nextDouble() * 0.25,
            );
            _attendance.add(
              _attendanceRecord(
                tenantId: tenant.id,
                studentId: enrollment.studentId,
                groupId: group.id,
                day: day,
                start: session.startTime,
                risk: risk,
                threshold: threshold,
                recorder: recorder,
              ),
            );
          }
        }
      }
    }
  }

  Attendance _attendanceRecord({
    required String tenantId,
    required String studentId,
    required String groupId,
    required DateTime day,
    required ClockTime start,
    required double risk,
    required int threshold,
    required String recorder,
    bool isMakeup = false,
  }) {
    final roll = _r.nextDouble();
    final presentP = 0.80 - risk;
    final lateP = presentP + 0.10;
    final excusedP = lateP + 0.04 + risk / 3;

    AttendanceStatus status;
    var offset = 0;
    if (roll < presentP) {
      status = AttendanceStatus.present;
      offset = _r.nextInt(threshold + 8) - 8;
    } else if (roll < lateP) {
      status = AttendanceStatus.late;
      offset = threshold + 1 + _r.nextInt(25);
    } else if (roll < excusedP) {
      status = AttendanceStatus.absentExcused;
    } else {
      status = AttendanceStatus.absent;
    }

    final attended = status == AttendanceStatus.present || status == AttendanceStatus.late;
    final byQr = attended && _r.nextDouble() < 0.9;
    return Attendance(
      id: _id('att'),
      tenantId: tenantId,
      studentId: studentId,
      groupId: groupId,
      date: day,
      status: status,
      lateMinutes: status == AttendanceStatus.late ? offset : 0,
      scanTime: attended ? start.onDate(day).add(Duration(minutes: offset)) : null,
      method: byQr ? AttendanceMethod.qr : AttendanceMethod.manual,
      isMakeup: isMakeup,
      excuseText: status == AttendanceStatus.absentExcused ? _pick(_excuses) : null,
      recordedBy: recorder,
    );
  }

  /// A few students of grp-a-1 attended grp-a-2 instead (تعويض).
  void _createMakeupAttendance() {
    final other = _groups.firstWhere((g) => g.id == 'grp-a-2');
    final session = other.sessions.first;
    var day = _today.subtract(const Duration(days: 1));
    while (day.weekday != session.weekday) {
      day = day.subtract(const Duration(days: 1));
    }
    final students = _enrollments
        .where((e) => e.groupId == 'grp-a-1')
        .take(3)
        .map((e) => e.studentId);
    for (final studentId in students) {
      _attendance.add(
        Attendance(
          id: _id('att'),
          tenantId: mainTenantId,
          studentId: studentId,
          groupId: other.id,
          date: day,
          status: AttendanceStatus.present,
          scanTime: session.startTime.onDate(day).add(const Duration(minutes: 3)),
          method: AttendanceMethod.qr,
          isMakeup: true,
          recordedBy: assistantUserId,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Payments: 6 months; older months almost all paid, current month partly paid.

  void _generatePayments(Tenant tenant) {
    final recorder = tenant.id == mainTenantId ? assistantUserId : secondTeacherUserId;
    final demoStudent = studentUserId(0);

    for (var monthOffset = -5; monthOffset <= 0; monthOffset++) {
      final month = AppDates.addMonths(_today, monthOffset);
      final key = AppDates.monthKey(month);
      final paidShare = switch (monthOffset) {
        0 => 0.6,
        -1 => 0.88,
        _ => 0.97,
      };

      for (final enrollment in _enrollments.where((e) => e.tenantId == tenant.id)) {
        if (enrollment.isExempt) continue;
        final isDemoCurrent = enrollment.studentId == demoStudent && monthOffset == 0;
        final isDemoPast = enrollment.studentId == demoStudent && monthOffset < 0;
        if (isDemoCurrent || (!isDemoPast && _r.nextDouble() > paidShare)) continue;

        final group = _groups.firstWhere((g) => g.id == enrollment.groupId);
        final grade = _grades.firstWhere((g) => g.id == group.gradeId);
        final amount = PricingService.monthlyPrice(
          enrollment: enrollment,
          group: group,
          grade: grade,
        );

        final maxDay = monthOffset == 0 ? min(_today.day, 10) : 12;
        final paidAt = DateTime(month.year, month.month, 1 + _r.nextInt(maxDay), 16, 30);
        final method = _paymentMethod(tenant);
        _payments.add(
          Payment(
            id: _id('pay'),
            tenantId: tenant.id,
            studentId: enrollment.studentId,
            month: key,
            amount: amount,
            method: method,
            referenceNumber: method == PaymentMethod.cash
                ? null
                : '${1000000000 + _r.nextInt(899999999)}',
            recordedBy: recorder,
            createdAt: paidAt,
          ),
        );
      }
    }
  }

  PaymentMethod _paymentMethod(Tenant tenant) {
    final roll = _r.nextDouble();
    final accepted = tenant.settings.acceptedPaymentMethods;
    if (roll < 0.6 || accepted.length == 1) return PaymentMethod.cash;
    if (roll < 0.82 && accepted.contains(PaymentMethod.vodafoneCash)) {
      return PaymentMethod.vodafoneCash;
    }
    if (accepted.contains(PaymentMethod.instaPay)) return PaymentMethod.instaPay;
    return PaymentMethod.cash;
  }

  // ---------------------------------------------------------------------------
  // Sheets & sales

  void _createSheets() {
    final specs = [
      ('g-a-1', 'مذكرة الباب الأول – أولى ثانوي', 40.0, 80, 45),
      ('g-a-2', 'مذكرة الكهربية – تانية ثانوي', 50.0, 70, 38),
      ('g-a-3', 'كتاب المراجعة النهائية – تالتة ثانوي', 120.0, 60, 53),
    ];
    for (final (gradeId, title, price, printed, sold) in specs) {
      final sheet = Sheet(
        id: _id('sheet'),
        tenantId: mainTenantId,
        gradeId: gradeId,
        title: title,
        price: price,
        printedQty: printed,
        createdAt: _today.subtract(const Duration(days: 45)),
      );
      _sheets.add(sheet);

      var remaining = sold;
      while (remaining > 0) {
        final qty = min(remaining, 1 + _r.nextInt(6));
        remaining -= qty;
        _sales.add(
          SheetSale(
            id: _id('sale'),
            tenantId: mainTenantId,
            sheetId: sheet.id,
            date: _today.subtract(Duration(days: 1 + _r.nextInt(40))),
            qty: qty,
            total: qty * price,
            recordedBy: assistantUserId,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Assessments & results

  void _createAssessments() {
    final specs = [
      ('g-a-3', AssessmentType.homework, 'واجب الحركة الدائرية', 20, null),
      ('g-a-3', AssessmentType.exam, 'امتحان الشهر – الجاذبية', 12, 30.0),
      ('g-a-1', AssessmentType.homework, 'واجب الوحدة الأولى', 15, 10.0),
      ('g-a-2', AssessmentType.exam, 'امتحان الكهربية التيارية', 8, 50.0),
    ];
    for (final (gradeId, type, title, daysAgo, maxScore) in specs) {
      final assessment = Assessment(
        id: _id('asm'),
        tenantId: mainTenantId,
        gradeId: gradeId,
        type: type,
        title: title,
        date: _today.subtract(Duration(days: daysAgo)),
        maxScore: maxScore,
      );
      _assessments.add(assessment);

      final groupIds = _groups.where((g) => g.gradeId == gradeId).map((g) => g.id).toSet();
      final students = _enrollments
          .where((e) => e.tenantId == mainTenantId && groupIds.contains(e.groupId))
          .map((e) => e.studentId);
      for (final studentId in students) {
        final took = _r.nextDouble() < (type == AssessmentType.homework ? 0.85 : 0.92);
        double? score;
        if (took && maxScore != null) {
          score = ((maxScore * (0.45 + _r.nextDouble() * 0.55)) * 2).round() / 2;
        }
        _results.add(
          AssessmentResult(
            id: _id('res'),
            tenantId: mainTenantId,
            assessmentId: assessment.id,
            studentId: studentId,
            delivered: took,
            score: score,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Requests, complaints, announcements, recorded lessons

  void _createCommunication() {
    DateTime ago(int days) => now.subtract(Duration(days: days, hours: 1));

    _requests.addAll([
      Request(
        id: _id('req'),
        tenantId: mainTenantId,
        fromUserId: studentUserId(0),
        fromRole: UserRole.student,
        studentId: studentUserId(0),
        type: RequestType.absence,
        text: 'عندي امتحان في المدرسة ومش هقدر أحضر الحصة الجاية.',
        date: _today.add(const Duration(days: 2)),
        createdAt: ago(0),
      ),
      Request(
        id: _id('req'),
        tenantId: mainTenantId,
        fromUserId: parentUserId(0),
        fromRole: UserRole.parent,
        studentId: studentUserId(50),
        type: RequestType.changeGroup,
        text: 'برجاء نقل ابنتي للمجموعة الأولى لتعارض الميعاد مع المدرسة.',
        requestedGroupId: 'grp-a-1',
        createdAt: ago(1),
      ),
      Request(
        id: _id('req'),
        tenantId: mainTenantId,
        fromUserId: studentUserId(5),
        fromRole: UserRole.student,
        studentId: studentUserId(5),
        type: RequestType.absence,
        text: 'تعبان ومش هقدر أحضر النهارده.',
        date: _today.subtract(const Duration(days: 6)),
        status: RequestStatus.approved,
        reply: 'ألف سلامة، ذاكر الدرس من المذكرة.',
        createdAt: ago(7),
      ),
      Request(
        id: _id('req'),
        tenantId: mainTenantId,
        fromUserId: parentUserId(3),
        fromRole: UserRole.parent,
        studentId: studentUserId(3),
        type: RequestType.other,
        text: 'هل ممكن تقسيط مصاريف الشهر على دفعتين؟',
        status: RequestStatus.rejected,
        reply: 'للأسف مش متاح، ممكن التواصل مع السكرتارية.',
        createdAt: ago(10),
      ),
      Request(
        id: _id('req'),
        tenantId: mainTenantId,
        fromUserId: studentUserId(12),
        fromRole: UserRole.student,
        studentId: studentUserId(12),
        type: RequestType.other,
        text: 'ممكن أحضر حصة تعويض مع المجموعة الأولى الأسبوع ده؟',
        status: RequestStatus.approved,
        reply: 'تمام، اعرض الكود على المساعد.',
        createdAt: ago(14),
      ),
    ]);

    _complaints.addAll([
      Complaint(
        id: _id('cmp'),
        tenantId: mainTenantId,
        studentId: studentUserId(50),
        toRole: UserRole.parent,
        kind: ComplaintKind.complaint,
        text: 'تكرر الغياب بدون عذر خلال الأسبوعين الماضيين، برجاء المتابعة.',
        byUserId: teacherUserId,
        createdAt: ago(3),
      ),
      Complaint(
        id: _id('cmp'),
        tenantId: mainTenantId,
        studentId: studentUserId(0),
        toRole: UserRole.student,
        kind: ComplaintKind.warning,
        text: 'برجاء الالتزام بتسليم الواجب في موعده.',
        byUserId: teacherUserId,
        createdAt: ago(5),
      ),
      Complaint(
        id: _id('cmp'),
        tenantId: mainTenantId,
        studentId: studentUserId(7),
        toRole: UserRole.parent,
        kind: ComplaintKind.complaint,
        text: 'الطالب لا يلتزم بالهدوء أثناء الحصة.',
        byUserId: assistantUserId,
        createdAt: ago(9),
      ),
    ]);

    _announcements.addAll([
      Announcement(
        id: _id('ann'),
        tenantId: mainTenantId,
        title: 'امتحان الشهر',
        body: 'امتحان الشهر يوم الخميس القادم في نفس ميعاد الحصة، المنهج حتى نهاية الفصل الثاني.',
        createdAt: ago(1),
      ),
      Announcement(
        id: _id('ann'),
        tenantId: mainTenantId,
        gradeId: 'g-a-3',
        title: 'حصة مراجعة إضافية',
        body: 'حصة مراجعة لطلاب تالتة ثانوي يوم الجمعة الساعة 5 مساءً.',
        createdAt: ago(4),
      ),
      Announcement(
        id: _id('ann'),
        tenantId: mainTenantId,
        gradeId: 'g-a-1',
        title: 'المذكرة الجديدة',
        body: 'مذكرة الباب الأول متاحة الآن عند المساعد.',
        createdAt: ago(8),
      ),
      Announcement(
        id: _id('ann'),
        tenantId: mainTenantId,
        title: 'مواعيد الدفع',
        body: 'آخر ميعاد لدفع اشتراك الشهر يوم 10، ويمكن الدفع عبر فودافون كاش أو إنستاباي.',
        createdAt: ago(20),
      ),
      Announcement(
        id: _id('ann'),
        tenantId: secondTenantId,
        title: 'أهلاً بكم',
        body: 'بداية الشرح من الباب الأول، برجاء إحضار الكشكول.',
        createdAt: ago(15),
      ),
    ]);

    _lessons.addAll([
      RecordedLesson(
        id: _id('les'),
        tenantId: mainTenantId,
        gradeId: 'g-a-3',
        title: 'شرح الحركة الدائرية – الجزء الأول',
        driveUrl: 'https://drive.google.com/drive/folders/demo-circular-motion-1',
        createdAt: ago(10),
      ),
      RecordedLesson(
        id: _id('les'),
        tenantId: mainTenantId,
        gradeId: 'g-a-3',
        title: 'حل امتحان الجاذبية',
        driveUrl: 'https://drive.google.com/drive/folders/demo-gravity-exam',
        createdAt: ago(6),
      ),
      RecordedLesson(
        id: _id('les'),
        tenantId: mainTenantId,
        gradeId: 'g-a-1',
        title: 'مقدمة في الفيزياء والقياس',
        driveUrl: 'https://drive.google.com/drive/folders/demo-measurement',
        createdAt: ago(18),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Expenses: 6 months (current included), only dates up to today.

  void _createExpenses() {
    for (var offset = -5; offset <= 0; offset++) {
      final month = AppDates.addMonths(_today, offset);
      void add(String title, ExpenseCategory category, double amount, int day) {
        final date = DateTime(month.year, month.month, day);
        if (date.isAfter(_today)) return;
        _expenses.add(
          Expense(
            id: _id('exp'),
            tenantId: mainTenantId,
            title: title,
            category: category,
            amount: amount,
            date: date,
          ),
        );
      }

      add('إيجار القاعة', ExpenseCategory.rent, 3000, 1);
      add('طباعة مذكرات', ExpenseCategory.printing, 600 + _r.nextInt(10) * 100.0, 8);
      add('رواتب المساعدين', ExpenseCategory.salaries, 4000, 25);
      if (_r.nextBool()) {
        add('مصروفات متنوعة', ExpenseCategory.other, 150 + _r.nextInt(6) * 50.0, 15);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // A few notifications so every demo account has something in the bell.

  void _createNotifications() {
    DateTime ago(int hours) => now.subtract(Duration(hours: hours));
    AppNotification n(
      String userId,
      String title,
      String body,
      NotificationType type,
      DateTime at, {
      bool read = false,
      String? tenantId = mainTenantId,
    }) => AppNotification(
      id: _id('ntf'),
      userId: userId,
      tenantId: tenantId,
      title: title,
      body: body,
      type: type,
      read: read,
      createdAt: at,
    );

    _notifications.addAll([
      n(teacherUserId, 'طلب جديد', 'طلب غياب جديد من طالب', NotificationType.request, ago(2)),
      n(
        teacherUserId,
        'طلب نقل مجموعة',
        'ولي أمر يطلب نقل ابنته لمجموعة أخرى',
        NotificationType.request,
        ago(20),
      ),
      n(
        studentUserId(0),
        'إعلان جديد',
        'امتحان الشهر يوم الخميس القادم',
        NotificationType.announcement,
        ago(22),
      ),
      n(
        studentUserId(0),
        'تنبيه',
        'برجاء الالتزام بتسليم الواجب في موعده',
        NotificationType.complaint,
        ago(110),
        read: true,
      ),
      n(
        parentUserId(0),
        'إعلان جديد',
        'امتحان الشهر يوم الخميس القادم',
        NotificationType.announcement,
        ago(22),
      ),
      n(
        parentUserId(0),
        'شكوى',
        'تكرر الغياب بدون عذر خلال الأسبوعين الماضيين',
        NotificationType.complaint,
        ago(70),
        read: true,
      ),
      n(
        assistantUserId,
        'إعلان جديد',
        'امتحان الشهر يوم الخميس القادم',
        NotificationType.announcement,
        ago(22),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Helpers

  T _pick<T>(List<T> items) => items[_r.nextInt(items.length)];

  static String _phone(String prefix, int index) => '$prefix${index.toString().padLeft(8, '0')}';

  String _linkCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    while (true) {
      final code = String.fromCharCodes(
        List.generate(6, (_) => alphabet.codeUnitAt(_r.nextInt(alphabet.length))),
      );
      if (_usedLinkCodes.add(code)) return code;
    }
  }
}
