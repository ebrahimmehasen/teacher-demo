import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/date_picker_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/filter_dropdown.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/models.dart';
import '../../../services/attendance_service.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';
import '../../shared/attendance/attendance_log_page.dart';

class ManualAttendancePage extends ConsumerStatefulWidget {
  const ManualAttendancePage({super.key});

  @override
  ConsumerState<ManualAttendancePage> createState() => _ManualAttendancePageState();
}

class _ManualAttendancePageState extends ConsumerState<ManualAttendancePage> {
  late DateTime _day = AppDates.dateOnly(ref.read(clockProvider)());
  String? _groupId;

  /// Draft entries by student id; null status = not set yet.
  final _draft = <String, ManualEntry>{};
  String? _loadedKey;
  var _saving = false;

  void _loadExisting(List<Attendance> records) {
    final key = '$_groupId|$_day';
    if (_loadedKey == key) return;
    _loadedKey = key;
    _draft
      ..clear()
      ..addAll({
        for (final a in records.where((a) => a.groupId == _groupId))
          a.studentId: ManualEntry(a.status, lateMinutes: a.lateMinutes, excuse: a.excuseText),
      });
  }

  Future<void> _save(Group group, List<User> students) async {
    final session = ref.read(sessionProvider);
    if (session == null || _draft.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(attendanceRecorderProvider)
          .saveManual(
            tenantId: group.tenantId,
            group: group,
            groupLabel: ref.read(groupLabelsProvider)[group.id] ?? '',
            day: _day,
            entries: Map.of(_draft),
            studentNames: {for (final s in students) s.id: s.name},
            recordedBy: session.user.id,
            now: ref.read(clockProvider)(),
          );
      if (mounted) showSuccessSnack(context, 'تم حفظ حضور ${_draft.length} طالب');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider).asData?.value ?? const <Group>[];
    final labels = ref.watch(groupLabelsProvider);
    final enrollments = ref.watch(enrollmentsProvider).asData?.value ?? const <Enrollment>[];
    final users = ref.watch(tenantStudentsProvider).asData?.value ?? const <String, User>{};
    final dayRecords = ref.watch(dayAttendanceProvider(_day));

    _groupId ??=
        AttendanceRules.currentGroup(groups, ref.read(clockProvider)())?.id ??
        groups.firstOrNull?.id;
    final group = groups.where((g) => g.id == _groupId).firstOrNull;
    if (dayRecords.hasValue) _loadExisting(dayRecords.requireValue);

    final students = [
      for (final e in enrollments)
        if (e.active && e.groupId == _groupId && users[e.studentId] != null) users[e.studentId]!,
    ]..sort((a, b) => a.name.compareTo(b.name));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterDropdown<String>(
                label: 'المجموعة',
                width: 280,
                allLabel: null,
                value: _groupId,
                items: labels,
                onChanged: (v) => setState(() => _groupId = v),
              ),
              DatePickerButton(
                date: _day,
                lastDate: AppDates.dateOnly(ref.read(clockProvider)()),
                onChanged: (d) => setState(() => _day = d),
              ),
              TextButton.icon(
                onPressed: students.isEmpty
                    ? null
                    : () => setState(() {
                        for (final s in students) {
                          _draft.putIfAbsent(
                            s.id,
                            () => const ManualEntry(AttendanceStatus.present),
                          );
                        }
                      }),
                icon: const Icon(Icons.done_all),
                label: const Text('الباقي حاضر'),
              ),
            ],
          ),
        ),
        if (group != null && AttendanceRules.sessionOn(group, _day) == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'تنبيه: ليس لهذه المجموعة حصة يوم ${AppDates.weekdayName(_day.weekday)}.',
              style: TextStyle(color: toneColor(context, StatusTone.warning)),
            ),
          ),
        const Divider(height: 16),
        Expanded(
          child: group == null || students.isEmpty
              ? const EmptyState(icon: Icons.groups_outlined, title: 'لا يوجد طلاب في هذه المجموعة')
              : !dayRecords.hasValue
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: students.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _StudentRow(
                    student: students[i],
                    entry: _draft[students[i].id],
                    defaultLate:
                        (ref
                                .read(currentTenantProvider)
                                .asData
                                ?.value
                                ?.settings
                                .lateThresholdMinutes ??
                            10) +
                        5,
                    onChanged: (entry) => setState(() => _draft[students[i].id] = entry),
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'تم تحديد ${_draft.length} من ${students.length}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: group == null || _draft.isEmpty || _saving
                      ? null
                      : () => _save(group, students),
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('حفظ الحضور'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.entry,
    required this.defaultLate,
    required this.onChanged,
  });

  final User student;
  final ManualEntry? entry;
  final int defaultLate;
  final ValueChanged<ManualEntry> onChanged;

  static const _shortLabels = {
    AttendanceStatus.present: 'حاضر',
    AttendanceStatus.late: 'متأخر',
    AttendanceStatus.absentExcused: 'بعذر',
    AttendanceStatus.absent: 'غائب',
  };

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(student.name, style: Theme.of(context).textTheme.titleSmall),
                SegmentedButton<AttendanceStatus>(
                  showSelectedIcon: false,
                  emptySelectionAllowed: true,
                  segments: [
                    for (final s in AttendanceStatus.values)
                      ButtonSegment(
                        value: s,
                        tooltip: s.label,
                        label: Text(_shortLabels[s]!),
                        icon: Icon(s.icon, size: 16, color: toneColor(context, s.tone)),
                      ),
                  ],
                  selected: {?entry?.status},
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) return;
                    final status = selection.first;
                    onChanged(
                      ManualEntry(
                        status,
                        lateMinutes: status == AttendanceStatus.late
                            ? (entry?.lateMinutes ?? 0) > 0
                                  ? entry!.lateMinutes
                                  : defaultLate
                            : 0,
                        excuse: entry?.excuse,
                      ),
                    );
                  },
                ),
              ],
            ),
            if (entry?.status == AttendanceStatus.late)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextFormField(
                  initialValue: '${entry!.lateMinutes}',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'دقائق التأخير',
                    isDense: true,
                    suffixText: 'دقيقة',
                  ),
                  onChanged: (v) => onChanged(
                    ManualEntry(AttendanceStatus.late, lateMinutes: int.tryParse(v) ?? 0),
                  ),
                ),
              ),
            if (entry?.status == AttendanceStatus.absentExcused)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextFormField(
                  initialValue: entry!.excuse ?? '',
                  decoration: const InputDecoration(labelText: 'العذر', isDense: true),
                  onChanged: (v) =>
                      onChanged(ManualEntry(AttendanceStatus.absentExcused, excuse: v)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
