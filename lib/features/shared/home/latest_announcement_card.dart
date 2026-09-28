import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/models/models.dart';
import '../../../services/student_context.dart';
import '../../../services/tenant_data.dart';

/// The most recent announcement visible to the active student (all-tenant or
/// their own grade), with a link to the full list. Renders nothing if there
/// are no announcements yet.
class LatestAnnouncementCard extends ConsumerWidget {
  const LatestAnnouncementCard({super.key, required this.seeAllPath});

  final String seeAllPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myGradeIds = {for (final g in ref.watch(activeStudentGradesProvider)) g.id};
    final all = ref.watch(announcementsProvider).asData?.value ?? const <Announcement>[];
    final visible = all.where((a) => a.isForAll || myGradeIds.contains(a.gradeId)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latest = visible.firstOrNull;
    if (latest == null) return const SizedBox.shrink();

    return SectionCard(
      title: 'آخر إعلان',
      subtitle: AppDates.dayMonth(latest.createdAt),
      trailing: TextButton(onPressed: () => context.go(seeAllPath), child: const Text('عرض الكل')),
      child: Text(latest.body, maxLines: 3, overflow: TextOverflow.ellipsis),
    );
  }
}
