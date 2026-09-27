import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/models.dart';
import '../../../services/session_service.dart';
import '../../../services/sheet_service.dart';
import '../../../services/tenant_data.dart';

class SheetSalesPage extends ConsumerWidget {
  const SheetSalesPage({super.key});

  Future<void> _sell(
    BuildContext context,
    WidgetRef ref,
    Sheet sheet,
    List<SheetSale> sales,
  ) async {
    final remaining = SheetStock.remaining(sheet, sales);
    final today = AppDates.dateOnly(ref.read(clockProvider)());
    final result = await showDialog<(int, DateTime)>(
      context: context,
      builder: (_) => _SaleDialog(sheet: sheet, remaining: remaining, initialDate: today),
    );
    if (result == null || !context.mounted) return;
    final (qty, date) = result;
    try {
      await ref
          .read(sheetSaleServiceProvider)
          .record(
            sheet: sheet,
            qty: qty,
            date: date,
            existingSales: sales,
            recordedBy: ref.read(sessionProvider)!.user.id,
          );
      if (context.mounted) {
        showSuccessSnack(context, 'تم تسجيل بيع $qty نسخة – ${Money.format(qty * sheet.price)}');
      }
    } on InsufficientStockException catch (e) {
      if (context.mounted) showErrorSnack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grades = {
      for (final g in ref.watch(gradesProvider).asData?.value ?? const <Grade>[]) g.id: g.name,
    };
    final sales = ref.watch(sheetSalesProvider).asData?.value ?? const <SheetSale>[];
    final today = AppDates.dateOnly(ref.watch(clockProvider)());
    final todaySales = sales.where((s) => AppDates.dateOnly(s.date) == today).toList();

    return AsyncValueView(
      value: ref.watch(sheetsProvider),
      builder: (sheets) {
        if (sheets.isEmpty) {
          return const EmptyState(icon: Icons.menu_book_outlined, title: 'لا توجد مذكرات بعد');
        }
        final titles = {for (final s in sheets) s.id: s.title};
        return PageContainer(
          children: [
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 380,
                mainAxisExtent: 200,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              children: [
                for (final sheet in sheets)
                  _SheetCard(
                    sheet: sheet,
                    gradeName: grades[sheet.gradeId] ?? '',
                    sold: SheetStock.sold(sheet.id, sales),
                    onSell: () => _sell(context, ref, sheet, sales),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'مبيعات اليوم',
              subtitle:
                  '${todaySales.fold<int>(0, (s, x) => s + x.qty)} نسخة • '
                  '${Money.format(todaySales.fold<double>(0, (s, x) => s + x.total))}',
              child: todaySales.isEmpty
                  ? const Text('لم يتم تسجيل مبيعات اليوم بعد.')
                  : Column(
                      children: [
                        for (final s in todaySales)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.receipt_outlined),
                            title: Text(titles[s.sheetId] ?? ''),
                            subtitle: Text('${s.qty} نسخة'),
                            trailing: Text(Money.format(s.total)),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({
    required this.sheet,
    required this.gradeName,
    required this.sold,
    required this.onSell,
  });

  final Sheet sheet;
  final String gradeName;
  final int sold;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = sheet.printedQty - sold;
    final low = SheetStock.isLow(remaining);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sheet.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            Text('$gradeName • ${Money.format(sheet.price)}', style: theme.textTheme.bodySmall),
            const Spacer(),
            Text('المطبوع ${sheet.printedQty} • المباع $sold', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: sheet.printedQty == 0 ? 0 : sold / sheet.printedQty,
              borderRadius: BorderRadius.circular(4),
              color: low ? toneColor(context, StatusTone.danger) : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                low
                    ? StatusChip(
                        label: 'متبقي $remaining فقط',
                        tone: StatusTone.danger,
                        icon: Icons.warning_amber,
                      )
                    : Text('المتبقي $remaining', style: theme.textTheme.titleSmall),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: remaining > 0 ? onSell : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('تسجيل بيع'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleDialog extends StatefulWidget {
  const _SaleDialog({required this.sheet, required this.remaining, required this.initialDate});

  final Sheet sheet;
  final int remaining;
  final DateTime initialDate;

  @override
  State<_SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<_SaleDialog> {
  var _qty = 1;
  late var _date = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.sheet.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('$_qty', style: theme.textTheme.headlineMedium),
              ),
              IconButton.outlined(
                onPressed: _qty < widget.remaining ? () => setState(() => _qty++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          Text('المتبقي ${widget.remaining} نسخة', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(
            'الإجمالي: ${Money.format(_qty * widget.sheet.price)}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: _date.subtract(const Duration(days: 30)),
                lastDate: widget.initialDate,
              );
              if (picked != null) setState(() => _date = picked);
            },
            icon: const Icon(Icons.event_outlined),
            label: Text('يوم البيع: ${AppDates.dayMonth(_date)}'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((_qty, _date)),
          child: const Text('تسجيل'),
        ),
      ],
    );
  }
}
