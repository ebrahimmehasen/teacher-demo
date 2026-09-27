import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';

class ResultEntry {
  const ResultEntry({required this.delivered, this.score});
  final bool delivered;
  final double? score;
}

abstract final class AssessmentRules {
  /// Null when valid, otherwise an Arabic message.
  static String? validateScore(double? score, Assessment assessment) {
    if (score == null) return null;
    final max = assessment.maxScore;
    if (score < 0) return 'الدرجة لا تكون سالبة';
    if (max != null && score > max) return 'الدرجة أكبر من النهاية العظمى ($max)';
    return null;
  }

  /// Keeps existing result ids so saving twice updates instead of duplicating.
  static List<AssessmentResult> buildResults(
    Assessment assessment,
    Map<String, ResultEntry> entries,
    Iterable<AssessmentResult> existing, {
    String Function()? newId,
  }) {
    final byStudent = {
      for (final r in existing.where((r) => r.assessmentId == assessment.id)) r.studentId: r,
    };
    final id = newId ?? const Uuid().v4;
    return [
      for (final MapEntry(key: studentId, value: entry) in entries.entries)
        AssessmentResult(
          id: byStudent[studentId]?.id ?? id(),
          tenantId: assessment.tenantId,
          assessmentId: assessment.id,
          studentId: studentId,
          delivered: entry.delivered,
          score: assessment.maxScore == null ? null : entry.score,
        ),
    ];
  }
}

class AssessmentService {
  AssessmentService(this._repo);
  final AssessmentRepository _repo;

  Future<void> saveResults(
    Assessment assessment,
    Map<String, ResultEntry> entries,
    Iterable<AssessmentResult> existing,
  ) {
    for (final e in entries.values) {
      final error = AssessmentRules.validateScore(e.score, assessment);
      if (error != null) throw ArgumentError(error);
    }
    return _repo.upsertResults(AssessmentRules.buildResults(assessment, entries, existing));
  }
}

final assessmentServiceProvider = Provider(
  (ref) => AssessmentService(ref.watch(assessmentRepositoryProvider)),
);
