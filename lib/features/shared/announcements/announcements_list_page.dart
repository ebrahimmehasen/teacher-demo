import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../services/student_context.dart';
import '../../../services/tenant_data.dart';

/// Rule 9: announcements for all students, plus the active student's own grade.
class AnnouncementsListPage extends ConsumerWidget {
  const AnnouncementsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myGradeIds = {for (final g in ref.watch(activeStudentGradesProvider)) g.id};
    return AsyncValueView(
      value: ref.watch(announcementsProvider),
      builder: (all) {
        final visible = all.where((a) => a.isForAll || myGradeIds.contains(a.gradeId)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (visible.isEmpty) {
          return const EmptyState(icon: Icons.campaign_outlined, title: 'لا توجد إعلانات بعد');
        }
        final theme = Theme.of(context);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final a = visible[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.campaign, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(AppDates.dayMonth(a.createdAt), style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(a.body, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
