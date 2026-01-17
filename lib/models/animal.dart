class Animal {
  final String id;
  final String name;
  final String type;
  final String breed;
  final DateTime birthDate;
  final DateTime? lastBirthDate;
  final DateTime? nextHeatDate;
  final String notes;
  
  // Minimalist takip alanları
  final List<VaccineRecord> vaccines;
  final List<MilkRecord> milkRecords;
  final double? dailyFeedAmount; // kg
  final double? monthlyFeedCost; // TL

  Animal({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.birthDate,
    this.lastBirthDate,
    this.nextHeatDate,
    this.notes = '',
    List<VaccineRecord>? vaccines,
    List<MilkRecord>? milkRecords,
    this.dailyFeedAmount,
    this.monthlyFeedCost,
  }) : vaccines = vaccines ?? [],
       milkRecords = milkRecords ?? [];

  int get ageInYears {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  int? get daysSinceLastBirth {
    if (lastBirthDate == null) return null;
    return DateTime.now().difference(lastBirthDate!).inDays;
  }

  int? get daysUntilNextHeat {
    if (nextHeatDate == null) return null;
    return nextHeatDate!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'breed': breed,
      'birthDate': birthDate.toIso8601String(),
      'lastBirthDate': lastBirthDate?.toIso8601String(),
      'nextHeatDate': nextHeatDate?.toIso8601String(),
      'notes': notes,
      'vaccines': vaccines.map((v) => v.toJson()).toList(),
      'milkRecords': milkRecords.map((m) => m.toJson()).toList(),
      'dailyFeedAmount': dailyFeedAmount,
      'monthlyFeedCost': monthlyFeedCost,
    };
  }

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      breed: json['breed'],
      birthDate: DateTime.parse(json['birthDate']),
      lastBirthDate: json['lastBirthDate'] != null
          ? DateTime.parse(json['lastBirthDate'])
          : null,
      nextHeatDate: json['nextHeatDate'] != null
          ? DateTime.parse(json['nextHeatDate'])
          : null,
      notes: json['notes'] ?? '',
      vaccines: (json['vaccines'] as List?)?.map((v) => VaccineRecord.fromJson(v)).toList(),
      milkRecords: (json['milkRecords'] as List?)?.map((m) => MilkRecord.fromJson(m)).toList(),
      dailyFeedAmount: json['dailyFeedAmount']?.toDouble(),
      monthlyFeedCost: json['monthlyFeedCost']?.toDouble(),
    );
  }

  Animal copyWith({
    String? id,
    String? name,
    String? type,
    String? breed,
    DateTime? birthDate,
    DateTime? lastBirthDate,
    DateTime? nextHeatDate,
    String? notes,
    List<VaccineRecord>? vaccines,
    List<MilkRecord>? milkRecords,
    double? dailyFeedAmount,
    double? monthlyFeedCost,
  }) {
    return Animal(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      lastBirthDate: lastBirthDate ?? this.lastBirthDate,
      nextHeatDate: nextHeatDate ?? this.nextHeatDate,
      notes: notes ?? this.notes,
      vaccines: vaccines ?? this.vaccines,
      milkRecords: milkRecords ?? this.milkRecords,
      dailyFeedAmount: dailyFeedAmount ?? this.dailyFeedAmount,
      monthlyFeedCost: monthlyFeedCost ?? this.monthlyFeedCost,
    );
  }
}

// Minimalist Aşı Kaydı
class VaccineRecord {
  final String name;
  final DateTime date;
  final DateTime? nextDate;

  VaccineRecord({
    required this.name,
    required this.date,
    this.nextDate,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date.toIso8601String(),
    'nextDate': nextDate?.toIso8601String(),
  };

  factory VaccineRecord.fromJson(Map<String, dynamic> json) => VaccineRecord(
    name: json['name'],
    date: DateTime.parse(json['date']),
    nextDate: json['nextDate'] != null ? DateTime.parse(json['nextDate']) : null,
  );
}

// Minimalist Süt Kaydı
class MilkRecord {
  final DateTime date;
  final double amount; // litre

  MilkRecord({
    required this.date,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'amount': amount,
  };

  factory MilkRecord.fromJson(Map<String, dynamic> json) => MilkRecord(
    date: DateTime.parse(json['date']),
    amount: json['amount'].toDouble(),
  );
}
