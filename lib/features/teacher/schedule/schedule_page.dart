import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/models.dart';
import '../../../data/repository_providers.dart';
import '../../../services/group_service.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';
import 'group_details_sheet.dart';
import 'group_form_dialog.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
    final grades = ref.watch(gradesProvider);
    final groups = ref.watch(groupsProvider);
    final periods = ref.watch(periodsProvider).asData?.value;
    final enrollments = ref.watch(enrollmentsProvider).asData?.value ?? const [];
    if (tenantId == null) return const SizedBox.shrink();

    return AsyncValueView(
      value: groups,
      builder: (groupList) {
        final gradeList = grades.asData?.value ?? const <Grade>[];
        final periodCount = periods?.count ?? 6;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: gradeList.isEmpty
                      ? null
                      : () => showGroupFormDialog(context, tenantId: tenantId),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة مجموعة'),
                ),
                OutlinedButton.icon(
                  onPressed: periods == null || periodCount >= 12
                      ? null
                      : () => ref
                            .read(groupRepositoryProvider)
                            .setPeriods(periods.copyWith(count: periodCount + 1)),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('إضافة فترة'),
                ),
                const _Legend(),
              ],
            ),
            const SizedBox(height: 16),
            if (gradeList.isEmpty)
              const EmptyState(
                icon: Icons.school_outlined,
                title: 'أضف الصفوف أولاً',
                message: 'من صفحة الإعدادات أضف الصفوف الدراسية، ثم أنشئ المجموعات هنا.',
              )
            else
              _ScheduleGrid(
                tenantId: tenantId,
                groups: groupList,
                grades: {for (final g in gradeList) g.id: g},
                enrollments: enrollments,
                periodCount: max(periodCount, GroupService.maxUsedPeriod(groupList) + 1),
              ),
          ],
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(Color color, IconData icon, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
    return Wrap(
      spacing: 16,
      children: [
        item(scheme.primary, Icons.groups_outlined, 'مجموعة عامة'),
        item(AppTheme.privateGroupColor, Icons.location_on_outlined, 'مجموعة خاصة'),
      ],
    );
  }
}

class _ScheduleGrid extends StatelessWidget {
  const _ScheduleGrid({
    required this.tenantId,
    required this.groups,
    required this.grades,
    required this.enrollments,
    required this.periodCount,
  });

  final String tenantId;
  final List<Group> groups;
  final Map<String, Grade> grades;
  final List<Enrollment> enrollments;
  final int periodCount;

  static const _headerWidth = 64.0;
  static const _minColumnWidth = 132.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7));

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = max(
          _minColumnWidth,
          (constraints.maxWidth - _headerWidth) / AppDates.weekOrder.length,
        );
        final tableWidth = _headerWidth + columnWidth * AppDates.weekOrder.length;

        Widget headerCell(String text) => Container(
          height: 44,
          alignment: Alignment.center,
          color: scheme.primaryContainer.withValues(alpha: 0.5),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        );

        return Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Table(
                border: TableBorder(horizontalInside: border, verticalInside: border),
                columnWidths: {
                  0: const FixedColumnWidth(_headerWidth),
                  for (var i = 1; i <= AppDates.weekOrder.length; i++)
                    i: FixedColumnWidth(columnWidth),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.top,
                children: [
                  TableRow(
                    children: [
                      headerCell('الفترة'),
                      for (final day in AppDates.weekOrder) headerCell(AppDates.weekdayName(day)),
                    ],
                  ),
                  for (var period = 0; period < periodCount; period++)
                    TableRow(
                      children: [
                        Container(
                          constraints: const BoxConstraints(minHeight: 88),
                          alignment: Alignment.center,
                          child: Text(
                            '${period + 1}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        for (final day in AppDates.weekOrder)
                          _Cell(
                            tenantId: tenantId,
                            weekday: day,
                            period: period,
                            entries: [
                              for (final g in groups)
                                for (final s in g.sessions)
                                  if (s.weekday == day && s.periodIndex == period) (g, s),
                            ],
                            grades: grades,
                            enrollments: enrollments,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.tenantId,
    required this.weekday,
    required this.period,
    required this.entries,
    required this.grades,
    required this.enrollments,
  });

  final String tenantId;
  final int weekday;
  final int period;
  final List<(Group, GroupSession)> entries;
  final Map<String, Grade> grades;
  final List<Enrollment> enrollments;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Tooltip(
        message: 'إضافة مجموعة في ${AppDates.weekdayName(weekday)} – الفترة ${period + 1}',
        child: InkWell(
          onTap: () =>
              showGroupFormDialog(context, tenantId: tenantId, initialSlot: (weekday, period)),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            alignment: Alignment.center,
            child: Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          for (final (group, session) in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _GroupChip(
                group: group,
                session: session,
                grade: grades[group.gradeId],
                enrolled: GroupService.enrolledCount(group.id, enrollments),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.group,
    required this.session,
    required this.grade,
    required this.enrolled,
  });

  final Group group;
  final GroupSession session;
  final Grade? grade;
  final int enrolled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = group.isPrivate ? AppTheme.privateGroupColor : theme.colorScheme.primary;
    final full = enrolled >= group.capacity;
    final small = theme.textTheme.bodySmall;

    return Material(
      color: color.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showGroupDetailsSheet(context, group),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(group.isPrivate ? Icons.location_on : Icons.groups, size: 14, color: color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      grade?.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small?.copyWith(fontWeight: FontWeight.w700, color: color),
                    ),
                  ),
                ],
              ),
              Text(GroupLabels.name(group.number), maxLines: 1, style: small),
              Text(
                '${AppDates.clock(session.startTime)} – ${AppDates.clock(session.endTime)}',
                maxLines: 1,
                style: small,
              ),
              Text(
                full ? 'مكتملة $enrolled/${group.capacity}' : '$enrolled/${group.capacity} طالب',
                style: small?.copyWith(
                  color: full ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                  fontWeight: full ? FontWeight.w700 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
