import 'enums.dart';

class Payment {
  const Payment({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.month,
    required this.amount,
    required this.method,
    required this.recordedBy,
    required this.createdAt,
    this.referenceNumber,
    this.note,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'] as String,
    tenantId: json['tenantId'] as String,
    studentId: json['studentId'] as String,
    month: json['month'] as String,
    amount: (json['amount'] as num).toDouble(),
    method: PaymentMethod.values.byName(json['method'] as String),
    referenceNumber: json['referenceNumber'] as String?,
    note: json['note'] as String?,
    recordedBy: json['recordedBy'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final String tenantId;
  final String studentId;

  /// Billing month in `yyyy-MM` format.
  final String month;
  final double amount;
  final PaymentMethod method;
  final String? referenceNumber;
  final String? note;
  final String recordedBy;
  final DateTime createdAt;

  Payment copyWith({
    String? month,
    double? amount,
    PaymentMethod? method,
    String? referenceNumber,
    String? note,
  }) => Payment(
    id: id,
    tenantId: tenantId,
    studentId: studentId,
    month: month ?? this.month,
    amount: amount ?? this.amount,
    method: method ?? this.method,
    referenceNumber: referenceNumber ?? this.referenceNumber,
    note: note ?? this.note,
    recordedBy: recordedBy,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenantId': tenantId,
    'studentId': studentId,
    'month': month,
    'amount': amount,
    'method': method.name,
    'referenceNumber': referenceNumber,
    'note': note,
    'recordedBy': recordedBy,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is Payment &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.studentId == studentId &&
      other.month == month &&
      other.amount == amount &&
      other.method == method &&
      other.referenceNumber == referenceNumber &&
      other.note == note &&
      other.recordedBy == recordedBy &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    studentId,
    month,
    amount,
    method,
    referenceNumber,
    note,
    recordedBy,
    createdAt,
  );
}

class Expense {
  const Expense({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    tenantId: json['tenantId'] as String,
    title: json['title'] as String,
    category: ExpenseCategory.values.byName(json['category'] as String),
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    note: json['note'] as String?,
  );

  final String id;
  final String tenantId;
  final String title;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? note;

  Expense copyWith({
    String? title,
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    String? note,
  }) => Expense(
    id: id,
    tenantId: tenantId,
    title: title ?? this.title,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    note: note ?? this.note,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenantId': tenantId,
    'title': title,
    'category': category.name,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
  };

  @override
  bool operator ==(Object other) =>
      other is Expense &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.title == title &&
      other.category == category &&
      other.amount == amount &&
      other.date == date &&
      other.note == note;

  @override
  int get hashCode => Object.hash(id, tenantId, title, category, amount, date, note);
}

/// A printed handout or book (مذكرة / كتاب) sold to students.
class Sheet {
  const Sheet({
    required this.id,
    required this.tenantId,
    required this.gradeId,
    required this.title,
    required this.price,
    required this.printedQty,
    required this.createdAt,
  });

  factory Sheet.fromJson(Map<String, dynamic> json) => Sheet(
    id: json['id'] as String,
    tenantId: json['tenantId'] as String,
    gradeId: json['gradeId'] as String,
    title: json['title'] as String,
    price: (json['price'] as num).toDouble(),
    printedQty: json['printedQty'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final String tenantId;
  final String gradeId;
  final String title;
  final double price;
  final int printedQty;
  final DateTime createdAt;

  Sheet copyWith({String? gradeId, String? title, double? price, int? printedQty}) => Sheet(
    id: id,
    tenantId: tenantId,
    gradeId: gradeId ?? this.gradeId,
    title: title ?? this.title,
    price: price ?? this.price,
    printedQty: printedQty ?? this.printedQty,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenantId': tenantId,
    'gradeId': gradeId,
    'title': title,
    'price': price,
    'printedQty': printedQty,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is Sheet &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.gradeId == gradeId &&
      other.title == title &&
      other.price == price &&
      other.printedQty == printedQty &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, tenantId, gradeId, title, price, printedQty, createdAt);
}

class SheetSale {
  const SheetSale({
    required this.id,
    required this.tenantId,
    required this.sheetId,
    required this.date,
    required this.qty,
    required this.total,
    required this.recordedBy,
  });

  factory SheetSale.fromJson(Map<String, dynamic> json) => SheetSale(
    id: json['id'] as String,
    tenantId: json['tenantId'] as String,
    sheetId: json['sheetId'] as String,
    date: DateTime.parse(json['date'] as String),
    qty: json['qty'] as int,
    total: (json['total'] as num).toDouble(),
    recordedBy: json['recordedBy'] as String,
  );

  final String id;
  final String tenantId;
  final String sheetId;
  final DateTime date;
  final int qty;
  final double total;
  final String recordedBy;

  SheetSale copyWith({DateTime? date, int? qty, double? total}) => SheetSale(
    id: id,
    tenantId: tenantId,
    sheetId: sheetId,
    date: date ?? this.date,
    qty: qty ?? this.qty,
    total: total ?? this.total,
    recordedBy: recordedBy,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenantId': tenantId,
    'sheetId': sheetId,
    'date': date.toIso8601String(),
    'qty': qty,
    'total': total,
    'recordedBy': recordedBy,
  };

  @override
  bool operator ==(Object other) =>
      other is SheetSale &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.sheetId == sheetId &&
      other.date == date &&
      other.qty == qty &&
      other.total == total &&
      other.recordedBy == recordedBy;

  @override
  int get hashCode => Object.hash(id, tenantId, sheetId, date, qty, total, recordedBy);
}
