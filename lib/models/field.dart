class Field {
  final String id;
  final String name;
  final double area; // dönüm cinsinden
  final String? currentCrop;
  final DateTime? plantingDate;
  final DateTime? harvestDate;
  final List<Task> tasks;

  Field({
    required this.id,
    required this.name,
    required this.area,
    this.currentCrop,
    this.plantingDate,
    this.harvestDate,
    List<Task>? tasks,
  }) : tasks = tasks ?? [];

  int get completedTasksCount => tasks.where((t) => t.isCompleted).length;
  int get totalTasksCount => tasks.length;
  double get progress => totalTasksCount > 0 ? completedTasksCount / totalTasksCount : 0;

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
      tasks: (json['tasks'] as List?)?.map((t) => Task.fromJson(t)).toList() ?? [],
    );
  }
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
