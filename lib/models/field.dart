enum FieldOwnership { own, rented }

class Field {
  final String id;
  final String name;
  final double area; // dönüm cinsinden
  final String? currentCrop;
  final DateTime? plantingDate;
  final DateTime? harvestDate;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final FieldOwnership ownership;
  final List<Task> tasks;

  Field({
    required this.id,
    required this.name,
    required this.area,
    this.currentCrop,
    this.plantingDate,
    this.harvestDate,
    this.latitude,
    this.longitude,
    this.locationName,
    this.ownership = FieldOwnership.own,
    List<Task>? tasks,
  }) : tasks = tasks ?? [];

  int get completedTasksCount => tasks.where((t) => t.isCompleted).length;
  int get totalTasksCount => tasks.length;
  double get progress => totalTasksCount > 0 ? completedTasksCount / totalTasksCount : 0;
  bool get hasLocation => latitude != null && longitude != null;

  bool get isEmpty => currentCrop == null;
  bool get hasUpcomingTask => tasks.any((t) => !t.isCompleted && t.dueDate != null && 
      t.dueDate!.isAfter(DateTime.now()) && 
      t.dueDate!.isBefore(DateTime.now().add(const Duration(days: 7))));
  bool get hasOverdueTask => tasks.any((t) => !t.isCompleted && t.dueDate != null && 
      t.dueDate!.isBefore(DateTime.now()));

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'currentCrop': currentCrop,
      'plantingDate': plantingDate?.toIso8601String(),
      'harvestDate': harvestDate?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'ownership': ownership.name,
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
  }

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'],
      name: json['name'],
      area: json['area'],
      currentCrop: json['currentCrop'],
      plantingDate: json['plantingDate'] != null ? DateTime.parse(json['plantingDate']) : null,
      harvestDate: json['harvestDate'] != null ? DateTime.parse(json['harvestDate']) : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['locationName'],
      ownership: _ownershipFromString(json['ownership']),
      tasks: (json['tasks'] as List?)?.map((t) => Task.fromJson(t)).toList() ?? [],
    );
  }

  Field copyWith({
    String? id,
    String? name,
    double? area,
    String? currentCrop,
    DateTime? plantingDate,
    DateTime? harvestDate,
    double? latitude,
    double? longitude,
    String? locationName,
    FieldOwnership? ownership,
    List<Task>? tasks,
  }) {
    return Field(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      currentCrop: currentCrop ?? this.currentCrop,
      plantingDate: plantingDate ?? this.plantingDate,
      harvestDate: harvestDate ?? this.harvestDate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      ownership: ownership ?? this.ownership,
      tasks: tasks ?? this.tasks,
    );
  }
}

FieldOwnership _ownershipFromString(dynamic value) {
  if (value is String) {
    return FieldOwnership.values.firstWhere(
      (o) => o.name == value,
      orElse: () => FieldOwnership.own,
    );
  }
  return FieldOwnership.own;
}

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;
  final TaskCategory category;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
    required this.category,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    TaskCategory? category,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'category': category.toString(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      category: TaskCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => TaskCategory.other,
      ),
    );
  }
}

enum TaskCategory {
  beforePlanting,  // Ekimden önce
  planting,        // Ekim sırası
  afterPlanting,   // Ekimden sonra
  maintenance,     // Bakım
  harvest,         // Hasat
  other,           // Diğer
}
