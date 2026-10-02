import 'farm_records.dart';

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
  final List<BreedingRecord> breedingRecords;
  final bool milkTrackingEnabled;
  final double? dailyFeedAmount; // kg
  final double? monthlyFeedCost; // TL
  final List<AnimalAttachment> attachments;

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
    List<BreedingRecord>? breedingRecords,
    bool? milkTrackingEnabled,
    this.dailyFeedAmount,
    this.monthlyFeedCost,
    List<AnimalAttachment>? attachments,
  }) : vaccines = vaccines ?? [],
       milkRecords = milkRecords ?? [],
       breedingRecords = breedingRecords ?? [],
       milkTrackingEnabled =
           milkTrackingEnabled ?? (milkRecords?.isNotEmpty ?? false),
       attachments = attachments ?? [];

  int get ageInYears {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  DateTime? get latestBirthDate {
    final dates = [
      if (lastBirthDate != null) lastBirthDate!,
      ...breedingRecords
          .where(
            (r) => r.status == BreedingStatus.born && r.actualBirthDate != null,
          )
          .map((r) => r.actualBirthDate!),
    ];
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.last;
  }

  int? get daysSinceLastBirth {
    final date = latestBirthDate;
    return date == null
        ? null
        : dayOnly(DateTime.now()).difference(dayOnly(date)).inDays;
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
      'breedingRecords': breedingRecords.map((m) => m.toJson()).toList(),
      'milkTrackingEnabled': milkTrackingEnabled,
      'dailyFeedAmount': dailyFeedAmount,
      'monthlyFeedCost': monthlyFeedCost,
      'attachments': attachments.map((a) => a.toJson()).toList(),
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
      vaccines: (json['vaccines'] as List?)
          ?.map((v) => VaccineRecord.fromJson(v))
          .toList(),
      milkRecords: (json['milkRecords'] as List?)
          ?.map((m) => MilkRecord.fromJson(m))
          .toList(),
      breedingRecords: (json['breedingRecords'] as List? ?? [])
          .map((m) => BreedingRecord.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      milkTrackingEnabled: json['milkTrackingEnabled'],
      dailyFeedAmount: json['dailyFeedAmount']?.toDouble(),
      monthlyFeedCost: json['monthlyFeedCost']?.toDouble(),
      attachments:
          (json['attachments'] as List?)
              ?.map((a) => AnimalAttachment.fromJson(a))
              .toList() ??
          [],
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
    List<BreedingRecord>? breedingRecords,
    bool? milkTrackingEnabled,
    double? dailyFeedAmount,
    double? monthlyFeedCost,
    List<AnimalAttachment>? attachments,
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
      breedingRecords: breedingRecords ?? this.breedingRecords,
      milkTrackingEnabled: milkTrackingEnabled ?? this.milkTrackingEnabled,
      dailyFeedAmount: dailyFeedAmount ?? this.dailyFeedAmount,
      monthlyFeedCost: monthlyFeedCost ?? this.monthlyFeedCost,
      attachments: attachments ?? this.attachments,
    );
  }
}

class AnimalAttachment {
  final String id;
  final String type; // photo, document, invoice etc.
  final String name;
  final String filePath;
  final DateTime addedAt;

  const AnimalAttachment({
    required this.id,
    required this.type,
    required this.name,
    required this.filePath,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'name': name,
    'filePath': filePath,
    'addedAt': addedAt.toIso8601String(),
  };

  factory AnimalAttachment.fromJson(Map<String, dynamic> json) =>
      AnimalAttachment(
        id: json['id'],
        type: json['type'] ?? 'document',
        name: json['name'] ?? 'Belge',
        filePath: json['filePath'],
        addedAt: DateTime.parse(json['addedAt']),
      );

  AnimalAttachment copyWith({
    String? id,
    String? type,
    String? name,
    String? filePath,
    DateTime? addedAt,
  }) {
    return AnimalAttachment(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

// Minimalist Aşı Kaydı
class VaccineRecord {
  final String name;
  final DateTime date;
  final DateTime? nextDate;

  VaccineRecord({required this.name, required this.date, this.nextDate});

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date.toIso8601String(),
    'nextDate': nextDate?.toIso8601String(),
  };

  factory VaccineRecord.fromJson(Map<String, dynamic> json) => VaccineRecord(
    name: json['name'],
    date: DateTime.parse(json['date']),
    nextDate: json['nextDate'] != null
        ? DateTime.parse(json['nextDate'])
        : null,
  );
}

// Minimalist Süt Kaydı
class MilkRecord {
  final DateTime date;
  final double amount; // litre

  MilkRecord({required this.date, required this.amount});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'amount': amount,
  };

  factory MilkRecord.fromJson(Map<String, dynamic> json) => MilkRecord(
    date: DateTime.parse(json['date']),
    amount: json['amount'].toDouble(),
  );
}
