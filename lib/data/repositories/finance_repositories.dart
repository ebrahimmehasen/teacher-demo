import '../models/models.dart';

abstract interface class PaymentRepository {
  Stream<List<Payment>> watchByTenant(String tenantId, {String? studentId, String? month});
  Future<Payment> add(Payment payment);
  Future<void> delete(String tenantId, String id);
}

abstract interface class ExpenseRepository {
  Stream<List<Expense>> watchByTenant(String tenantId);
  Future<Expense> add(Expense expense);
  Future<void> update(Expense expense);
  Future<void> delete(String tenantId, String id);
}

abstract interface class SheetRepository {
  Stream<List<Sheet>> watchSheets(String tenantId);
  Stream<List<SheetSale>> watchSales(String tenantId);
  Future<Sheet> addSheet(Sheet sheet);
  Future<void> updateSheet(Sheet sheet);
  Future<SheetSale> addSale(SheetSale sale);
}
