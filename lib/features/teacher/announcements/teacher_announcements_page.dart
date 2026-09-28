import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../data/models/models.dart';
import '../../../data/repository_providers.dart';
import '../../../services/announcement_service.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';
import 'announcement_form_dialog.dart';

class TeacherAnnouncementsPage extends ConsumerWidget {
  const TeacherAnnouncementsPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final grades = ref.read(gradesProvider).asData?.value ?? const <Grade>[];
    final draft = await showAnnouncementFormDialog(context, grades);
    if (draft == null) return;

    final session = ref.read(sessionProvider)!;
    final enrollments = ref.read(enrollmentsProvider).asData?.value ?? const <Enrollment>[];
    final groups = ref.read(groupsProvider).asData?.value ?? const <Group>[];
    final targetGroupIds = draft.gradeId == null
        ? null
        : {for (final g in groups.where((g) => g.gradeId == draft.gradeId)) g.id};
    final targetStudentIds = {
      for (final e in enrollments)
        if (e.active && (targetGroupIds == null || targetGroupIds.contains(e.groupId))) e.studentId,
    };

    await ref
        .read(announcementServiceProvider)
        .create(
          tenantId: session.tenantId!,
          title: draft.title,
          body: draft.body,
          gradeId: draft.gradeId,
          targetStudentIds: targetStudentIds,
          now: ref.read(clockProvider)(),
        );
    if (context.mounted) showSuccessSnack(context, 'تم نشر الإعلان');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Announcement a) async {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف الإعلان',
      message: 'هل تريد حذف "${a.title}"؟',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(announcementRepositoryProvider).delete(a.tenantId, a.id);
    if (context.mounted) showSuccessSnack(context, 'تم حذف الإعلان');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradeNames = {
      for (final g in ref.watch(gradesProvider).asData?.value ?? const <Grade>[]) g.id: g.name,
    };

    return AsyncValueView(
      value: ref.watch(announcementsProvider),
      builder: (all) {
        final sorted = [...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return PageContainer(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: () => _create(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('إعلان جديد'),
              ),
            ),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              const EmptyState(icon: Icons.campaign_outlined, title: 'لا توجد إعلانات بعد')
            else
              for (final a in sorted)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(a.title),
                    subtitle: Text(
                      '${a.isForAll ? 'كل الطلاب' : gradeNames[a.gradeId] ?? ''} • '
                      '${AppDates.dayMonth(a.createdAt)}\n${a.body}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'حذف',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, ref, a),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
