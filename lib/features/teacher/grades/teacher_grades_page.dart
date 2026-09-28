import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/widgets/snackbars.dart';
import '../../../data/models/models.dart';
import '../../../data/repository_providers.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';
import '../../assistant/grades/grades_entry_page.dart';
import 'assessment_form_dialog.dart';

/// Teacher view: create assessments, then enter results with the same
/// widget the assistant uses (role-agnostic, tenant-scoped).
class TeacherGradesPage extends ConsumerWidget {
  const TeacherGradesPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final grades = ref.read(gradesProvider).asData?.value ?? const <Grade>[];
    if (grades.isEmpty) {
      showErrorSnack(context, 'أضف صفاً أولاً من الإعدادات');
      return;
    }
    final session = ref.read(sessionProvider)!;
    final today = ref.read(clockProvider)();
    final draft = await showAssessmentFormDialog(context, grades, today);
    if (draft == null) return;

    await ref
        .read(assessmentRepositoryProvider)
        .addAssessment(
          Assessment(
            id: const Uuid().v4(),
            tenantId: session.tenantId!,
            gradeId: draft.gradeId,
            type: draft.type,
            title: draft.title,
            date: draft.date,
            maxScore: draft.maxScore,
          ),
        );
    if (context.mounted) showSuccessSnack(context, 'تمت الإضافة');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('واجب / امتحان جديد'),
            ),
          ),
        ),
        const Divider(height: 1),
        const Expanded(child: GradesEntryPage()),
      ],
    );
  }
}
