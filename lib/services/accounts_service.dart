import '../core/utils/date_utils.dart';
import '../data/models/models.dart';

class MonthSummary {
  const MonthSummary({
    required this.month,
    required this.paymentsIncome,
    required this.sheetsIncome,
    required this.expenses,
  });

  final String month;
  final double paymentsIncome;
  final double sheetsIncome;
  final double expenses;

  double get income => paymentsIncome + sheetsIncome;
  double get net => income - expenses;
}

/// Rule 11: income = payments + sheet sales; net = income − expenses; per month.
abstract final class AccountsService {
  /// Payments count toward the month they pay for; sales/expenses toward their date.
  static MonthSummary summarize(
    String month, {
    required Iterable<Payment> payments,
    required Iterable<SheetSale> sales,
    required Iterable<Expense> expenses,
  }) {
    double sum<T>(Iterable<T> rows, bool Function(T) inMonth, double Function(T) amount) =>
        rows.where(inMonth).fold<double>(0, (s, r) => s + amount(r));

    return MonthSummary(
      month: month,
      paymentsIncome: sum<Payment>(payments, (p) => p.month == month, (p) => p.amount),
      sheetsIncome: sum<SheetSale>(
        sales,
        (s) => AppDates.monthKey(s.date) == month,
        (s) => s.total,
      ),
      expenses: sum<Expense>(expenses, (e) => AppDates.monthKey(e.date) == month, (e) => e.amount),
    );
  }

  /// The last [count] months ending with [today]'s month, oldest first.
  static List<MonthSummary> lastMonths(
    DateTime today,
    int count, {
    required Iterable<Payment> payments,
    required Iterable<SheetSale> sales,
    required Iterable<Expense> expenses,
  }) => [
    for (var offset = count - 1; offset >= 0; offset--)
      summarize(
        AppDates.monthKey(AppDates.addMonths(today, -offset)),
        payments: payments,
        sales: sales,
        expenses: expenses,
      ),
  ];
}
