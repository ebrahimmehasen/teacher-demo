import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../data/models/models.dart';
import '../../../data/repository_providers.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';
import 'lesson_form_dialog.dart';

class TeacherLessonsPage extends ConsumerWidget {
  const TeacherLessonsPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final grades = ref.read(gradesProvider).asData?.value ?? const <Grade>[];
    if (grades.isEmpty) {
      showErrorSnack(context, 'أضف صفاً أولاً من الإعدادات');
      return;
    }
    final draft = await showLessonFormDialog(context, grades);
    if (draft == null) return;
    final session = ref.read(sessionProvider)!;
    await ref
        .read(lessonRepositoryProvider)
        .add(
          RecordedLesson(
            id: const Uuid().v4(),
            tenantId: session.tenantId!,
            gradeId: draft.gradeId,
            title: draft.title,
            driveUrl: draft.driveUrl,
            createdAt: ref.read(clockProvider)(),
          ),
        );
    if (context.mounted) showSuccessSnack(context, 'تمت إضافة الحصة');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, RecordedLesson lesson) async {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف الحصة',
      message: 'هل تريد حذف "${lesson.title}"؟',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(lessonRepositoryProvider).delete(lesson.tenantId, lesson.id);
    if (context.mounted) showSuccessSnack(context, 'تم الحذف');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradeNames = {
      for (final g in ref.watch(gradesProvider).asData?.value ?? const <Grade>[]) g.id: g.name,
    };

    return AsyncValueView(
      value: ref.watch(lessonsProvider),
      builder: (all) {
        final sorted = [...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return PageContainer(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: () => _add(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('إضافة حصة'),
              ),
            ),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              const EmptyState(icon: Icons.video_library_outlined, title: 'لا توجد حصص مسجلة بعد')
            else
              for (final l in sorted)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.play_circle_outline)),
                    title: Text(l.title),
                    subtitle: Text(
                      '${gradeNames[l.gradeId] ?? ''} • ${AppDates.dayMonth(l.createdAt)}',
                    ),
                    trailing: IconButton(
                      tooltip: 'حذف',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, ref, l),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
