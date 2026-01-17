class Animal {
  final String id;
  final String name;
  final String type;
  final String breed;
  final DateTime birthDate;
  final DateTime? lastBirthDate;
  final DateTime? nextHeatDate;
  final String notes;

  Animal({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.birthDate,
    this.lastBirthDate,
    this.nextHeatDate,
    this.notes = '',
  });

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
    );
  }
}
