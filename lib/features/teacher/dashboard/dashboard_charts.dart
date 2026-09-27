import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../services/accounts_service.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/payment_status_service.dart';
import 'dashboard_providers.dart';

/// Series colors validated with the dataviz palette checker (light & dark).
abstract final class _Series {
  static const income = Color(0xFF0D9488);
  static Color expenses(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFD95926)
      : const Color(0xFFEB6834);
}

TextStyle? _axisStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

FlGridData _grid(BuildContext context, double interval) => FlGridData(
  drawVerticalLine: false,
  horizontalInterval: interval,
  getDrawingHorizontalLine: (_) => FlLine(
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    strokeWidth: 1,
  ),
);

Color _tooltipBg(BuildContext context) => Theme.of(context).colorScheme.inverseSurface;
TextStyle _tooltipText(BuildContext context) => TextStyle(
  color: Theme.of(context).colorScheme.onInverseSurface,
  fontFamily: 'Cairo',
  fontSize: 12,
  fontWeight: FontWeight.w600,
);

/// Charts read left→right in time, even inside the RTL app.
Widget _ltr(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

class LegendItem extends StatelessWidget {
  const LegendItem({super.key, required this.color, required this.label, this.icon});

  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      icon != null
          ? Icon(icon, size: 14, color: color)
          : Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class AttendanceLineChart extends StatelessWidget {
  const AttendanceLineChart({super.key, required this.days});

  final List<DailyAttendance> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const Center(child: Text('لا توجد حصص في آخر 30 يوم'));
    final style = _axisStyle(context);
    final labelEvery = max(1, (days.length / 6).ceil());

    return _ltr(
      LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: _grid(context, 25),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 25,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text('${v.toInt()}%', style: style),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= days.length || i % labelEvery != 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(AppDates.dayShort(days[i].day), style: style),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => _tooltipBg(context),
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    '${AppDates.dayMonth(days[s.x.toInt()].day)}\n'
                    '${s.y.round()}% (${days[s.x.toInt()].attended}/${days[s.x.toInt()].total})',
                    _tooltipText(context),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < days.length; i++) FlSpot(i.toDouble(), days[i].rate * 100),
              ],
              isCurved: true,
              preventCurveOverShooting: true,
              color: _Series.income,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: _Series.income.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}

class IncomeExpenseChart extends StatelessWidget {
  const IncomeExpenseChart({super.key, required this.months});

  final List<MonthSummary> months;

  @override
  Widget build(BuildContext context) {
    final style = _axisStyle(context);
    final expensesColor = _Series.expenses(context);
    final peak = months.fold<double>(0, (m, s) => max(m, max(s.income, s.expenses)));
    final interval = peak <= 0 ? 1000.0 : _niceInterval(peak / 4);
    final compact = NumberFormat.compact(locale: 'en');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          children: [
            const LegendItem(color: _Series.income, label: 'الدخل'),
            LegendItem(color: expensesColor, label: 'المصروفات'),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _ltr(
            BarChart(
              BarChartData(
                maxY: interval * (peak / interval).ceil().clamp(1, 1000),
                gridData: _grid(context, interval),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: interval,
                      getTitlesWidget: (v, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(compact.format(v), style: style),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, meta) {
                        final month = AppDates.parseMonthKey(months[v.toInt()].month);
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(AppDates.monthYear(month).split(' ').first, style: style),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => _tooltipBg(context),
                    getTooltipItem: (group, _, rod, rodIndex) {
                      final m = months[group.x];
                      final label = rodIndex == 0 ? 'الدخل' : 'المصروفات';
                      return BarTooltipItem(
                        '$label: ${Money.format(rod.toY)}\nالصافي: ${Money.format(m.net)}',
                        _tooltipText(context),
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < months.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 2,
                      barRods: [
                        _rod(months[i].income, _Series.income),
                        _rod(months[i].expenses, expensesColor),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static BarChartRodData _rod(double value, Color color) => BarChartRodData(
    toY: value,
    color: color,
    width: 12,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
  );
}

double _niceInterval(double raw) {
  final magnitude = pow(10, (log(raw) / ln10).floor()).toDouble();
  for (final step in [1, 2, 2.5, 5, 10]) {
    if (raw <= step * magnitude) return step * magnitude;
  }
  return 10 * magnitude;
}

class PaymentStatusByGradeChart extends StatelessWidget {
  const PaymentStatusByGradeChart({super.key, required this.grades});

  final List<GradePaymentStatus> grades;

  static const _order = [
    PaymentStatus.paid,
    PaymentStatus.due,
    PaymentStatus.overdue,
    PaymentStatus.exempt,
  ];

  @override
  Widget build(BuildContext context) {
    final style = _axisStyle(context);
    final surface = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    final peak = grades.fold<int>(
      0,
      (m, g) => max(m, g.counts.values.fold<int>(0, (s, c) => s + c)),
    );
    final interval = peak <= 10 ? 2.0 : _niceInterval(peak / 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            for (final s in _order)
              LegendItem(color: toneColor(context, s.tone), label: s.label, icon: s.icon),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _ltr(
            BarChart(
              BarChartData(
                maxY: interval * (peak / interval).ceil().clamp(1, 1000),
                gridData: _grid(context, interval),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: interval,
                      getTitlesWidget: (v, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text('${v.toInt()}', style: style),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(grades[v.toInt()].grade.name, style: style),
                      ),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => _tooltipBg(context),
                    getTooltipItem: (group, _, _, _) {
                      final g = grades[group.x];
                      return BarTooltipItem(
                        [
                          g.grade.name,
                          for (final s in _order) '${s.label}: ${g.counts[s] ?? 0}',
                        ].join('\n'),
                        _tooltipText(context),
                      );
                    },
                  ),
                ),
                barGroups: [for (var i = 0; i < grades.length; i++) _stack(context, i, surface)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _stack(BuildContext context, int index, Color surface) {
    final counts = grades[index].counts;
    var from = 0.0;
    final items = <BarChartRodStackItem>[];
    for (final s in _order) {
      final count = (counts[s] ?? 0).toDouble();
      if (count == 0) continue;
      items.add(
        BarChartRodStackItem(
          from,
          from + count,
          toneColor(context, s.tone),
          borderSide: BorderSide(color: surface, width: 1),
        ),
      );
      from += count;
    }
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: from,
          width: 28,
          rodStackItems: items,
          color: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}
