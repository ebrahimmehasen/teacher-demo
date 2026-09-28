import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/models/models.dart';
import '../../../services/report_service.dart';
import '../../../services/session_service.dart';
import '../../../services/student_context.dart';
import '../../../services/tenant_data.dart';
import 'attendance_breakdown_bar.dart';
import 'level_badge.dart';

enum _RangePreset { week, month, custom }

/// Rule 6: attendance %, absence %, late count, average score and a level
/// badge for the active student over a chosen date range.
class StudentReportPage extends ConsumerStatefulWidget {
  const StudentReportPage({super.key});

  @override
  ConsumerState<StudentReportPage> createState() => _StudentReportPageState();
}

class _StudentReportPageState extends ConsumerState<StudentReportPage> {
  var _preset = _RangePreset.month;
  DateTimeRange? _customRange;

  DateTimeRange _rangeFor(_RangePreset preset, DateTime now) {
    final today = AppDates.dateOnly(now);
    return switch (preset) {
      _RangePreset.week => DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      _RangePreset.month => DateTimeRange(
        start: today.subtract(const Duration(days: 29)),
        end: today,
      ),
      _RangePreset.custom =>
        _customRange ?? DateTimeRange(start: today.subtract(const Duration(days: 29)), end: today),
    };
  }

  Future<void> _pickCustomRange(DateTime now) async {
    final today = AppDates.dateOnly(now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
      initialDateRange: _rangeFor(_RangePreset.custom, now),
    );
    if (picked == null) return;
    setState(() {
      _preset = _RangePreset.custom;
      _customRange = DateTimeRange(
        start: AppDates.dateOnly(picked.start),
        end: AppDates.dateOnly(picked.end),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider)();
    final tenant = ref.watch(currentTenantProvider).asData?.value;
    final attendance =
        ref.watch(activeStudentAttendanceProvider).asData?.value ?? const <Attendance>[];
    final results =
        ref.watch(activeStudentResultsProvider).asData?.value ?? const <AssessmentResult>[];
    final assessments = {
      for (final a in ref.watch(assessmentsProvider).asData?.value ?? const <Assessment>[]) a.id: a,
    };

    final range = _rangeFor(_preset, now);
    final report = ReportService.calculate(
      from: range.start,
      to: range.end,
      attendance: attendance,
      results: results,
      assessmentsById: assessments,
      attendanceWeight: tenant?.settings.attendanceWeight ?? 40,
      gradesWeight: tenant?.settings.gradesWeight ?? 60,
    );

    return PageContainer(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<_RangePreset>(
              segments: const [
                ButtonSegment(value: _RangePreset.week, label: Text('أسبوع')),
                ButtonSegment(value: _RangePreset.month, label: Text('شهر')),
                ButtonSegment(value: _RangePreset.custom, label: Text('تحديد')),
              ],
              selected: {_preset},
              onSelectionChanged: (s) {
                if (s.first == _RangePreset.custom) {
                  _pickCustomRange(now);
                } else {
                  setState(() => _preset = s.first);
                }
              },
            ),
            Text(
              '${AppDates.dayMonth(range.start)} – ${AppDates.dayMonth(range.end)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(child: LevelBadge(level: report.level)),
        const SizedBox(height: 16),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisExtent: 88,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          children: [
            _Stat(label: 'نسبة الحضور', value: '${report.attendanceRate.round()}%'),
            _Stat(label: 'نسبة الغياب', value: '${report.absenceRate.round()}%'),
            _Stat(label: 'مرات التأخير', value: '${report.lateCount}'),
            _Stat(
              label: 'متوسط الدرجات',
              value: report.averageScorePercent == null
                  ? '—'
                  : '${report.averageScorePercent!.round()}%',
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'توزيع الحضور',
          subtitle: '${report.totalSessions} حصة في هذه الفترة',
          child: AttendanceBreakdownBar(report: report),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
