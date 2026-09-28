import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../data/models/models.dart';
import '../../../data/repository_providers.dart';
import '../../../services/accounts_service.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/payment_status_service.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';
import 'expense_form_dialog.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  DateTime? _month;

  Future<void> _addExpense(DateTime month) async {
    final session = ref.read(sessionProvider)!;
    final draft = await showExpenseFormDialog(context, initialDate: month);
    if (draft == null) return;
    await ref
        .read(expenseRepositoryProvider)
        .add(
          Expense(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            tenantId: session.tenantId!,
            title: draft.title,
            category: draft.category,
            amount: draft.amount,
            date: draft.date,
            note: draft.note,
          ),
        );
    if (mounted) showSuccessSnack(context, 'تمت الإضافة');
  }

  Future<void> _deleteExpense(Expense expense) async {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف المصروف',
      message: 'هل تريد حذف "${expense.title}"؟',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(expenseRepositoryProvider).delete(expense.tenantId, expense.id);
    if (mounted) showSuccessSnack(context, 'تم الحذف');
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final month = _month ?? DateTime(now.year, now.month);
    final monthKey = AppDates.monthKey(month);

    final payments = ref.watch(paymentsProvider).asData?.value ?? const <Payment>[];
    final sales = ref.watch(sheetSalesProvider).asData?.value ?? const <SheetSale>[];
    final expenses = ref.watch(expensesProvider).asData?.value ?? const <Expense>[];
    final grades = ref.watch(gradesProvider).asData?.value ?? const <Grade>[];
    final groups = ref.watch(groupsProvider).asData?.value ?? const <Group>[];
    final enrollments = ref.watch(enrollmentsProvider).asData?.value ?? const <Enrollment>[];

    final summary = AccountsService.summarize(
      monthKey,
      payments: payments,
      sales: sales,
      expenses: expenses,
    );
    final monthExpenses = expenses.where((e) => AppDates.monthKey(e.date) == monthKey).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final billing = DashboardService.billing(
      month: monthKey,
      today: now,
      enrollments: enrollments,
      groups: groups,
      grades: grades,
      payments: payments,
    );

    return PageContainer(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton.outlined(
              onPressed: () => setState(() => _month = AppDates.addMonths(month, -1)),
              icon: const Icon(Icons.chevron_right),
            ),
            Text(AppDates.monthYear(month), style: Theme.of(context).textTheme.titleMedium),
            IconButton.outlined(
              onPressed: () => setState(() => _month = AppDates.addMonths(month, 1)),
              icon: const Icon(Icons.chevron_left),
            ),
            FilledButton.icon(
              onPressed: () => _addExpense(month),
              icon: const Icon(Icons.add),
              label: const Text('مصروف جديد'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisExtent: 100,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          children: [
            StatCard(
              label: 'الدخل',
              value: Money.format(summary.income),
              icon: Icons.trending_up,
              caption: 'اشتراكات ${Money.format(summary.paymentsIncome)}',
            ),
            StatCard(
              label: 'المصروفات',
              value: Money.format(summary.expenses),
              icon: Icons.trending_down,
            ),
            StatCard(
              label: 'الصافي',
              value: Money.format(summary.net),
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'حالة الاشتراكات حسب الصف',
          child: Column(
            children: [
              for (final grade in grades)
                Builder(
                  builder: (context) {
                    final rows = billing.where((b) => b.grade.id == grade.id).toList();
                    final paid = rows.where((b) => b.status == PaymentStatus.paid).length;
                    final overdue = rows.where((b) => b.status == PaymentStatus.overdue).length;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(grade.name),
                      subtitle: Text('${rows.length} طالب'),
                      trailing: Text(
                        'مدفوع $paid • متأخر $overdue',
                        style: TextStyle(
                          color: overdue > 0 ? Theme.of(context).colorScheme.error : null,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'المصروفات',
          child: monthExpenses.isEmpty
              ? const Text('لا توجد مصروفات مسجلة هذا الشهر.')
              : Column(
                  children: [
                    for (final e in monthExpenses)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.title),
                        subtitle: Text('${e.category.label} • ${AppDates.dayMonth(e.date)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(Money.format(e.amount)),
                            IconButton(
                              tooltip: 'حذف',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteExpense(e),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
