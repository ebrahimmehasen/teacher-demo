/// A school year taught by the teacher (الصف), e.g. تالتة ثانوي.
class Grade {
  const Grade({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.publicPrice,
    required this.dueDay,
    required this.graceDays,
    required this.defaultCapacity,
  }) : assert(dueDay >= 1 && dueDay <= 28);

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        id: json['id'] as String,
        tenantId: json['tenantId'] as String,
        name: json['name'] as String,
        publicPrice: (json['publicPrice'] as num).toDouble(),
        dueDay: json['dueDay'] as int,
        graceDays: json['graceDays'] as int,
        defaultCapacity: json['defaultCapacity'] as int,
      );

  final String id;
  final String tenantId;
  final String name;
  final double publicPrice;
  final int dueDay;
  final int graceDays;
  final int defaultCapacity;

  Grade copyWith({
    String? name,
    double? publicPrice,
    int? dueDay,
    int? graceDays,
    int? defaultCapacity,
  }) =>
      Grade(
        id: id,
        tenantId: tenantId,
        name: name ?? this.name,
        publicPrice: publicPrice ?? this.publicPrice,
        dueDay: dueDay ?? this.dueDay,
        graceDays: graceDays ?? this.graceDays,
        defaultCapacity: defaultCapacity ?? this.defaultCapacity,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'name': name,
        'publicPrice': publicPrice,
        'dueDay': dueDay,
        'graceDays': graceDays,
        'defaultCapacity': defaultCapacity,
      };

  @override
  bool operator ==(Object other) =>
      other is Grade &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.name == name &&
      other.publicPrice == publicPrice &&
      other.dueDay == dueDay &&
      other.graceDays == graceDays &&
      other.defaultCapacity == defaultCapacity;

  @override
  int get hashCode =>
      Object.hash(id, tenantId, name, publicPrice, dueDay, graceDays, defaultCapacity);
}
