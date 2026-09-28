import 'package:flutter/material.dart';

import '../../../core/constants/labels.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/enums.dart';
import '../../../services/report_service.dart';

/// A small horizontal stacked bar of present/late/excused/absent counts.
class AttendanceBreakdownBar extends StatelessWidget {
  const AttendanceBreakdownBar({super.key, required this.report});
  final ReportResult report;

  static const _order = [
    AttendanceStatus.present,
    AttendanceStatus.late,
    AttendanceStatus.absentExcused,
    AttendanceStatus.absent,
  ];

  @override
  Widget build(BuildContext context) {
    final counts = {
      AttendanceStatus.present: report.presentCount,
      AttendanceStatus.late: report.lateCount,
      AttendanceStatus.absentExcused: report.excusedCount,
      AttendanceStatus.absent: report.absentCount,
    };
    if (report.totalSessions == 0) {
      return const Text('لا توجد حصص في هذه الفترة.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 20,
            child: Row(
              children: [
                for (final s in _order)
                  if (counts[s]! > 0)
                    Expanded(
                      flex: counts[s]!,
                      child: Container(
                        color: toneColor(context, s.tone),
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final s in _order)
              if (counts[s]! > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: toneColor(context, s.tone),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${s.label} ${counts[s]}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
          ],
        ),
      ],
    );
  }
}
