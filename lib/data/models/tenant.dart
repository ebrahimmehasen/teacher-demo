import 'package:flutter/foundation.dart';

import 'enums.dart';

class TenantSettings {
  const TenantSettings({
    this.lateThresholdMinutes = 10,
    this.acceptedPaymentMethods = const {PaymentMethod.cash},
    this.walletNumbers = const {},
    this.attendanceWeight = 40,
    this.gradesWeight = 60,
  });

  factory TenantSettings.fromJson(Map<String, dynamic> json) => TenantSettings(
        lateThresholdMinutes: json['lateThresholdMinutes'] as int,
        acceptedPaymentMethods: {
          for (final m in json['acceptedPaymentMethods'] as List)
            PaymentMethod.values.byName(m as String),
        },
        walletNumbers: {
          for (final e in (json['walletNumbers'] as Map).entries)
            PaymentMethod.values.byName(e.key as String): e.value as String,
        },
        attendanceWeight: json['attendanceWeight'] as int,
        gradesWeight: json['gradesWeight'] as int,
      );

  final int lateThresholdMinutes;
  final Set<PaymentMethod> acceptedPaymentMethods;

  /// Text shown to parents per method (wallet number, InstaPay handle, bank account).
  final Map<PaymentMethod, String> walletNumbers;

  /// Level weights in percent; they sum to 100.
  final int attendanceWeight;
  final int gradesWeight;

  TenantSettings copyWith({
    int? lateThresholdMinutes,
    Set<PaymentMethod>? acceptedPaymentMethods,
    Map<PaymentMethod, String>? walletNumbers,
    int? attendanceWeight,
    int? gradesWeight,
  }) =>
      TenantSettings(
        lateThresholdMinutes: lateThresholdMinutes ?? this.lateThresholdMinutes,
        acceptedPaymentMethods: acceptedPaymentMethods ?? this.acceptedPaymentMethods,
        walletNumbers: walletNumbers ?? this.walletNumbers,
        attendanceWeight: attendanceWeight ?? this.attendanceWeight,
        gradesWeight: gradesWeight ?? this.gradesWeight,
      );

  Map<String, dynamic> toJson() => {
        'lateThresholdMinutes': lateThresholdMinutes,
        'acceptedPaymentMethods': [for (final m in acceptedPaymentMethods) m.name],
        'walletNumbers': {for (final e in walletNumbers.entries) e.key.name: e.value},
        'attendanceWeight': attendanceWeight,
        'gradesWeight': gradesWeight,
      };

  @override
  bool operator ==(Object other) =>
      other is TenantSettings &&
      other.lateThresholdMinutes == lateThresholdMinutes &&
      setEquals(other.acceptedPaymentMethods, acceptedPaymentMethods) &&
      mapEquals(other.walletNumbers, walletNumbers) &&
      other.attendanceWeight == attendanceWeight &&
      other.gradesWeight == gradesWeight;

  @override
  int get hashCode => Object.hash(
        lateThresholdMinutes,
        Object.hashAllUnordered(acceptedPaymentMethods),
        Object.hashAllUnordered(walletNumbers.entries.map((e) => Object.hash(e.key, e.value))),
        attendanceWeight,
        gradesWeight,
      );
}

class Tenant {
  const Tenant({
    required this.id,
    required this.ownerUserId,
    required this.teacherName,
    required this.subject,
    required this.phone,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
    required this.settings,
    this.logoUrl,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
        id: json['id'] as String,
        ownerUserId: json['ownerUserId'] as String,
        teacherName: json['teacherName'] as String,
        subject: json['subject'] as String,
        phone: json['phone'] as String,
        logoUrl: json['logoUrl'] as String?,
        subscriptionPlan: SubscriptionPlan.values.byName(json['subscriptionPlan'] as String),
        subscriptionStatus:
            SubscriptionStatus.values.byName(json['subscriptionStatus'] as String),
        settings: TenantSettings.fromJson(json['settings'] as Map<String, dynamic>),
      );

  final String id;
  final String ownerUserId;
  final String teacherName;
  final String subject;
  final String phone;
  final String? logoUrl;
  final SubscriptionPlan subscriptionPlan;
  final SubscriptionStatus subscriptionStatus;
  final TenantSettings settings;

  Tenant copyWith({
    String? teacherName,
    String? subject,
    String? phone,
    String? logoUrl,
    SubscriptionPlan? subscriptionPlan,
    SubscriptionStatus? subscriptionStatus,
    TenantSettings? settings,
  }) =>
      Tenant(
        id: id,
        ownerUserId: ownerUserId,
        teacherName: teacherName ?? this.teacherName,
        subject: subject ?? this.subject,
        phone: phone ?? this.phone,
        logoUrl: logoUrl ?? this.logoUrl,
        subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
        subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
        settings: settings ?? this.settings,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerUserId': ownerUserId,
        'teacherName': teacherName,
        'subject': subject,
        'phone': phone,
        'logoUrl': logoUrl,
        'subscriptionPlan': subscriptionPlan.name,
        'subscriptionStatus': subscriptionStatus.name,
        'settings': settings.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      other is Tenant &&
      other.id == id &&
      other.ownerUserId == ownerUserId &&
      other.teacherName == teacherName &&
      other.subject == subject &&
      other.phone == phone &&
      other.logoUrl == logoUrl &&
      other.subscriptionPlan == subscriptionPlan &&
      other.subscriptionStatus == subscriptionStatus &&
      other.settings == settings;

  @override
  int get hashCode => Object.hash(id, ownerUserId, teacherName, subject, phone, logoUrl,
      subscriptionPlan, subscriptionStatus, settings);
}
