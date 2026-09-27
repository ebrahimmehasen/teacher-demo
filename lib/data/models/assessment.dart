import 'enums.dart';

class Assessment {
  const Assessment({
    required this.id,
    required this.tenantId,
    required this.gradeId,
    required this.type,
    required this.title,
    required this.date,
    this.maxScore,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) => Assessment(
    id: json['id'] as String,
    tenantId: json['tenantId'] as String,
    gradeId: json['gradeId'] as String,
    type: AssessmentType.values.byName(json['type'] as String),
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    maxScore: (json['maxScore'] as num?)?.toDouble(),
  );

  final String id;
  final String tenantId;
  final String gradeId;
  final AssessmentType type;
  final String title;
  final DateTime date;

  /// Null for homework that is only tracked as delivered / not delivered.
  final double? maxScore;

  Assessment copyWith({
    String? gradeId,
    AssessmentType? type,
    String? title,
    DateTime? date,
    double? maxScore,
  }) => Assessment(
    id: id,
    tenantId: tenantId,
    gradeId: gradeId ?? this.gradeId,
    type: type ?? this.type,
    title: title ?? this.title,
    date: date ?? this.date,
    maxScore: maxScore ?? this.maxScore,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenantId': tenantId,
    'gradeId': gradeId,
    'type': type.name,
    'title': title,
    'date': date.toIso8601String(),
    'maxScore': maxScore,
  };

  @override
  bool operator ==(Object other) =>
      other is Assessment &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.gradeId == gradeId &&
      other.type == type &&
      other.title == title &&
      other.date == date &&
      other.maxScore == maxScore;

  @override
  int get hashCode => Object.hash(id, tenantId, gradeId, type, title, date, maxScore);
}

class AssessmentResult {
  const AssessmentResult({
    required this.id,
    required this.tenantId,
    required this.assessmentId,
    required this.studentId,
    this.delivered = false,
    this.score,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) => AssessmentResult(
    id: json['id'] as String,
    tenantId: json['tenantId'] as String,
    assessmentId: json['assessmentId'] as String,
    studentId: json['studentId'] as String,
    delivered: json['delivered'] as bool,
    score: (json['score'] as num?)?.toDouble(),
  );

  final String id;
  final String tenantId;
  final String assessmentId;
  final String studentId;
  final bool delivered;
  final double? score;

  AssessmentResult copyWith({bool? delivered, double? score}) => AssessmentResult(
    id: id,
    tenantId: tenantId,
    assessmentId: assessmentId,
    studentId: studentId,
    delivered: delivered ?? this.delivered,
    score: score ?? this.score,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenantId': tenantId,
    'assessmentId': assessmentId,
    'studentId': studentId,
    'delivered': delivered,
    'score': score,
  };

  @override
  bool operator ==(Object other) =>
      other is AssessmentResult &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.assessmentId == assessmentId &&
      other.studentId == studentId &&
      other.delivered == delivered &&
      other.score == score;

  @override
  int get hashCode => Object.hash(id, tenantId, assessmentId, studentId, delivered, score);
}
