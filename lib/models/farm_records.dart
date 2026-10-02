import 'dart:math';

String recordId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
DateTime dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);
bool sameDay(DateTime a, DateTime b) => dayOnly(a) == dayOnly(b);
int? parseUnits(String text, int digits) {
  final value = text.trim().replaceAll(',', '.');
  if (!RegExp('^\\d+(?:\\.\\d{1,$digits})?\$').hasMatch(value)) return null;
  final parts = value.split('.');
  final whole = int.tryParse(parts[0]);
  if (whole == null || whole > 1000000000) return null;
  return whole * pow(10, digits).toInt() +
      int.parse(parts.length == 1 ? '0' : parts[1].padRight(digits, '0'));
}

String unitsText(int value, int digits) =>
    (value / pow(10, digits)).toStringAsFixed(digits).replaceAll('.', ',');

enum BreedingStatus { pending, pregnant, notPregnant, born, lost }

extension BreedingLabel on BreedingStatus {
  String get label => switch (this) {
    BreedingStatus.pending => 'Kontrol bekleniyor',
    BreedingStatus.pregnant => 'Gebelik doğrulandı',
    BreedingStatus.notPregnant => 'Gebe değil',
    BreedingStatus.born => 'Doğum gerçekleşti',
    BreedingStatus.lost => 'Gebelik sonlandı',
  };
  bool get active =>
      this == BreedingStatus.pending || this == BreedingStatus.pregnant;
}

class BreedingRecord {
  final String id;
  final DateTime inseminationDate;
  final DateTime? checkDate, expectedBirthDate, actualBirthDate;
  final BreedingStatus status;
  final List<String> offspringIds;
  final String notes;
  const BreedingRecord({
    required this.id,
    required this.inseminationDate,
    this.checkDate,
    this.expectedBirthDate,
    this.actualBirthDate,
    this.status = BreedingStatus.pending,
    this.offspringIds = const [],
    this.notes = '',
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'inseminationDate': inseminationDate.toIso8601String(),
    'checkDate': checkDate?.toIso8601String(),
    'expectedBirthDate': expectedBirthDate?.toIso8601String(),
    'actualBirthDate': actualBirthDate?.toIso8601String(),
    'status': status.name,
    'offspringIds': offspringIds,
    'notes': notes,
  };
  factory BreedingRecord.fromJson(Map<String, dynamic> j) => BreedingRecord(
    id: j['id'],
    inseminationDate: DateTime.parse(j['inseminationDate']),
    checkDate: j['checkDate'] == null ? null : DateTime.parse(j['checkDate']),
    expectedBirthDate: j['expectedBirthDate'] == null
        ? null
        : DateTime.parse(j['expectedBirthDate']),
    actualBirthDate: j['actualBirthDate'] == null
        ? null
        : DateTime.parse(j['actualBirthDate']),
    status: BreedingStatus.values.byName(j['status']),
    offspringIds: List<String>.from(j['offspringIds'] ?? []),
    notes: j['notes'] ?? '',
  );
}

class StockMovement {
  final String id;
  final DateTime date;
  final int quantityMilli; // Signed: positive receipt, negative consumption.
  final String note;
  const StockMovement({
    required this.id,
    required this.date,
    required this.quantityMilli,
    this.note = '',
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'quantityMilli': quantityMilli,
    'note': note,
  };
  factory StockMovement.fromJson(Map<String, dynamic> j) => StockMovement(
    id: j['id'],
    date: DateTime.parse(j['date']),
    quantityMilli: j['quantityMilli'],
    note: j['note'] ?? '',
  );
}

class StockItem {
  final String id, name, unit;
  final int minimumMilli;
  final List<StockMovement> movements;
  const StockItem({
    required this.id,
    required this.name,
    required this.unit,
    this.minimumMilli = 0,
    this.movements = const [],
  });
  int get balanceMilli => movements.fold(0, (sum, m) => sum + m.quantityMilli);
  bool get low => balanceMilli <= minimumMilli;
  StockItem copyWith({
    String? name,
    String? unit,
    int? minimumMilli,
    List<StockMovement>? movements,
  }) => StockItem(
    id: id,
    name: name ?? this.name,
    unit: unit ?? this.unit,
    minimumMilli: minimumMilli ?? this.minimumMilli,
    movements: movements ?? this.movements,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit': unit,
    'minimumMilli': minimumMilli,
    'movements': movements.map((m) => m.toJson()).toList(),
  };
  factory StockItem.fromJson(Map<String, dynamic> j) => StockItem(
    id: j['id'],
    name: j['name'],
    unit: j['unit'],
    minimumMilli: j['minimumMilli'] ?? 0,
    movements: (j['movements'] as List? ?? [])
        .map((m) => StockMovement.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
  );
}

class FinanceRecord {
  final String id, category, note;
  final bool income;
  final DateTime date;
  final int amountKurus;
  final String? ownerType, ownerId, ownerName;
  const FinanceRecord({
    required this.id,
    required this.category,
    required this.income,
    required this.date,
    required this.amountKurus,
    this.note = '',
    this.ownerType,
    this.ownerId,
    this.ownerName,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'income': income,
    'date': date.toIso8601String(),
    'amountKurus': amountKurus,
    'note': note,
    'ownerType': ownerType,
    'ownerId': ownerId,
    'ownerName': ownerName,
  };
  factory FinanceRecord.fromJson(Map<String, dynamic> j) => FinanceRecord(
    id: j['id'],
    category: j['category'],
    income: j['income'],
    date: DateTime.parse(j['date']),
    amountKurus: j['amountKurus'],
    note: j['note'] ?? '',
    ownerType: j['ownerType'],
    ownerId: j['ownerId'],
    ownerName: j['ownerName'],
  );
}
