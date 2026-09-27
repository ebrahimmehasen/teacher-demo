import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/date_picker_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/filter_dropdown.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/models.dart';
import '../../../data/repository_providers.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';

/// Live attendance of one day for the current tenant.
final dayAttendanceProvider = StreamProvider.family<List<Attendance>, DateTime>((ref, day) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  if (tenantId == null) return Stream.value(const []);
  return ref.watch(attendanceRepositoryProvider).watchByTenant(tenantId, from: day, to: day);
});

class AttendanceLogPage extends ConsumerStatefulWidget {
  const AttendanceLogPage({super.key});

  @override
  ConsumerState<AttendanceLogPage> createState() => _AttendanceLogPageState();
}

class _AttendanceLogPageState extends ConsumerState<AttendanceLogPage> {
  late DateTime _day = AppDates.dateOnly(ref.read(clockProvider)());
  String? _groupId;
  var _query = '';
  final _statuses = <AttendanceStatus>{};

  @override
  Widget build(BuildContext context) {
    final labels = ref.watch(groupLabelsProvider);
    final students = ref.watch(tenantStudentsProvider).asData?.value ?? const <String, User>{};

    return AsyncValueView(
      value: ref.watch(dayAttendanceProvider(_day)),
      builder: (records) {
        final inGroup = records.where((a) => _groupId == null || a.groupId == _groupId).toList();
        final visible =
            inGroup.where((a) {
              if (_statuses.isNotEmpty && !_statuses.contains(a.status)) return false;
              final name = students[a.studentId]?.name ?? '';
              return _query.isEmpty || name.contains(_query);
            }).toList()..sort(
              (a, b) =>
                  (students[a.studentId]?.name ?? '').compareTo(students[b.studentId]?.name ?? ''),
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SearchFilterBar(
                hint: 'بحث باسم الطالب',
                onSearch: (q) => setState(() => _query = q.trim()),
                filters: [
                  DatePickerButton(date: _day, onChanged: (d) => setState(() => _day = d)),
                  FilterDropdown<String>(
                    label: 'المجموعة',
                    width: 240,
                    value: _groupId,
                    items: labels,
                    onChanged: (v) => setState(() => _groupId = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in AttendanceStatus.values)
                    FilterChip(
                      avatar: Icon(s.icon, size: 16, color: toneColor(context, s.tone)),
                      label: Text('${s.label} ${inGroup.where((a) => a.status == s).length}'),
                      selected: _statuses.contains(s),
                      onSelected: (v) => setState(() => v ? _statuses.add(s) : _statuses.remove(s)),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.person_off_outlined, size: 16),
                    label: const Text('الغياب فقط'),
                    onPressed: () => setState(() {
                      _statuses
                        ..clear()
                        ..addAll([AttendanceStatus.absent, AttendanceStatus.absentExcused]);
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: visible.isEmpty
                  ? EmptyState(
                      icon: Icons.fact_check_outlined,
                      title: records.isEmpty
                          ? 'لا يوجد حضور مسجل في هذا اليوم'
                          : 'لا توجد نتائج مطابقة',
                      message: AppDates.dayMonth(_day),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _AttendanceTile(
                        record: visible[i],
                        studentName: students[visible[i].studentId]?.name ?? '—',
                        groupLabel: labels[visible[i].groupId] ?? '',
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({
    required this.record,
    required this.studentName,
    required this.groupLabel,
  });

  final Attendance record;
  final String studentName;
  final String groupLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final details = [
      groupLabel,
      if (record.scanTime != null) AppDates.time(record.scanTime!),
      if (record.status == AttendanceStatus.late) 'تأخير ${record.lateMinutes} دقيقة',
      record.method == AttendanceMethod.qr ? 'QR' : 'يدوي',
    ].join(' • ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(child: Text(studentName.characters.first)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(studentName, style: theme.textTheme.titleSmall)),
                      if (record.isMakeup) ...[
                        const SizedBox(width: 6),
                        const StatusChip(
                          label: 'تعويض',
                          tone: StatusTone.info,
                          icon: Icons.swap_horiz,
                        ),
                      ],
                    ],
                  ),
                  Text(details, style: muted),
                  if (record.excuseText != null) Text('العذر: ${record.excuseText}', style: muted),
                ],
              ),
            ),
            StatusChip.attendance(record.status),
          ],
        ),
      ),
    );
  }
}
