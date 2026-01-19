class PlantAnalysis {
  final String id;
  final DateTime timestamp;
  final String imagePath;
  final String plantName;
  final String scientificName;
  final String status;
  final double confidence;
  final List<String> diseases;
  final List<String> treatments;
  final List<String> careAdvice;
  final List<String> preventionTips;
  final String wateringSchedule;
  final String fertilizingSchedule;
  final String? harvestTime;

  PlantAnalysis({
    required this.id,
    required this.timestamp,
    required this.imagePath,
    required this.plantName,
    required this.scientificName,
    required this.status,
    required this.confidence,
    required this.diseases,
    required this.treatments,
    required this.careAdvice,
    required this.preventionTips,
    required this.wateringSchedule,
    required this.fertilizingSchedule,
    this.harvestTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'plantName': plantName,
      'scientificName': scientificName,
      'status': status,
      'confidence': confidence,
      'diseases': diseases,
      'treatments': treatments,
      'careAdvice': careAdvice,
      'preventionTips': preventionTips,
      'wateringSchedule': wateringSchedule,
      'fertilizingSchedule': fertilizingSchedule,
      'harvestTime': harvestTime,
    };
  }

  factory PlantAnalysis.fromJson(Map<String, dynamic> json) {
    return PlantAnalysis(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imagePath: json['imagePath'] as String,
      plantName: json['plantName'] as String,
      scientificName: json['scientificName'] as String,
      status: json['status'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      diseases: List<String>.from(json['diseases'] as List),
      treatments: List<String>.from(json['treatments'] as List),
      careAdvice: List<String>.from(json['careAdvice'] as List),
      preventionTips: List<String>.from(json['preventionTips'] as List),
      wateringSchedule: json['wateringSchedule'] as String,
      fertilizingSchedule: json['fertilizingSchedule'] as String,
      harvestTime: json['harvestTime'] as String?,
    );
  }
}
