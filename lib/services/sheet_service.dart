import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';

class InsufficientStockException implements Exception {
  const InsufficientStockException(this.remaining);
  final int remaining;

  @override
  String toString() => 'المتبقي $remaining نسخة فقط';
}

/// Rule 10: remaining = printedQty − sum(sales); warn below [lowStockThreshold].
abstract final class SheetStock {
  static const lowStockThreshold = 10;

  static int sold(String sheetId, Iterable<SheetSale> sales) =>
      sales.where((s) => s.sheetId == sheetId).fold(0, (sum, s) => sum + s.qty);

  static int remaining(Sheet sheet, Iterable<SheetSale> sales) =>
      sheet.printedQty - sold(sheet.id, sales);

  static bool isLow(int remaining) => remaining < lowStockThreshold;
}

class SheetSaleService {
  SheetSaleService(this._sheets);
  final SheetRepository _sheets;
  static const _uuid = Uuid();

  /// Throws [InsufficientStockException] when [qty] exceeds the remaining stock.
  Future<SheetSale> record({
    required Sheet sheet,
    required int qty,
    required DateTime date,
    required Iterable<SheetSale> existingSales,
    required String recordedBy,
  }) async {
    if (qty <= 0) throw ArgumentError.value(qty, 'qty', 'must be positive');
    final remaining = SheetStock.remaining(sheet, existingSales);
    if (qty > remaining) throw InsufficientStockException(remaining);
    return _sheets.addSale(
      SheetSale(
        id: _uuid.v4(),
        tenantId: sheet.tenantId,
        sheetId: sheet.id,
        date: date,
        qty: qty,
        total: qty * sheet.price,
        recordedBy: recordedBy,
      ),
    );
  }
}

final sheetSaleServiceProvider = Provider(
  (ref) => SheetSaleService(ref.watch(sheetRepositoryProvider)),
);
