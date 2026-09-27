import '../models/models.dart';
import '../repositories/repositories.dart';
import 'mock_database.dart';

class MockPaymentRepository implements PaymentRepository {
  MockPaymentRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<Payment>> watchByTenant(String tenantId, {String? studentId, String? month}) =>
      _db.payments.watch(
        (p) =>
            p.tenantId == tenantId &&
            (studentId == null || p.studentId == studentId) &&
            (month == null || p.month == month),
        sort: (a, b) => b.createdAt.compareTo(a.createdAt),
      );

  @override
  Future<Payment> add(Payment payment) async {
    await _db.delay();
    _db.payments.insert(payment);
    return payment;
  }

  @override
  Future<void> delete(String tenantId, String id) async {
    await _db.delay();
    _db.payments.removeWhere((p) => p.tenantId == tenantId && p.id == id);
  }
}

class MockExpenseRepository implements ExpenseRepository {
  MockExpenseRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<Expense>> watchByTenant(String tenantId) =>
      _db.expenses.watch((e) => e.tenantId == tenantId, sort: (a, b) => b.date.compareTo(a.date));

  @override
  Future<Expense> add(Expense expense) async {
    await _db.delay();
    _db.expenses.insert(expense);
    return expense;
  }

  @override
  Future<void> update(Expense expense) async {
    await _db.delay();
    _db.expenses.replace(expense);
  }

  @override
  Future<void> delete(String tenantId, String id) async {
    await _db.delay();
    _db.expenses.removeWhere((e) => e.tenantId == tenantId && e.id == id);
  }
}

class MockSheetRepository implements SheetRepository {
  MockSheetRepository(this._db);
  final MockDatabase _db;

  @override
  Stream<List<Sheet>> watchSheets(String tenantId) => _db.sheets.watch(
    (s) => s.tenantId == tenantId,
    sort: (a, b) => b.createdAt.compareTo(a.createdAt),
  );

  @override
  Stream<List<SheetSale>> watchSales(String tenantId) =>
      _db.sheetSales.watch((s) => s.tenantId == tenantId, sort: (a, b) => b.date.compareTo(a.date));

  @override
  Future<Sheet> addSheet(Sheet sheet) async {
    await _db.delay();
    _db.sheets.insert(sheet);
    return sheet;
  }

  @override
  Future<void> updateSheet(Sheet sheet) async {
    await _db.delay();
    _db.sheets.replace(sheet);
  }

  @override
  Future<SheetSale> addSale(SheetSale sale) async {
    await _db.delay();
    _db.sheetSales.insert(sale);
    return sale;
  }
}
