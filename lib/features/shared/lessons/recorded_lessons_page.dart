import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../data/models/models.dart';
import '../../../services/student_context.dart';
import '../../../services/tenant_data.dart';

/// Recorded lessons for the active student's grade(s), opening the Drive link.
class RecordedLessonsPage extends ConsumerWidget {
  const RecordedLessonsPage({super.key});

  Future<void> _open(BuildContext context, RecordedLesson lesson) async {
    final uri = Uri.tryParse(lesson.driveUrl);
    final ok = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showErrorSnack(context, 'تعذر فتح الرابط');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myGradeIds = {for (final g in ref.watch(activeStudentGradesProvider)) g.id};
    return AsyncValueView(
      value: ref.watch(lessonsProvider),
      builder: (all) {
        final visible = all.where((l) => myGradeIds.contains(l.gradeId)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (visible.isEmpty) {
          return const EmptyState(
            icon: Icons.video_library_outlined,
            title: 'لا توجد حصص مسجلة بعد',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final l = visible[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.play_circle_outline)),
                title: Text(l.title),
                subtitle: Text(AppDates.dayMonth(l.createdAt)),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _open(context, l),
              ),
            );
          },
        );
      },
    );
  }
}
