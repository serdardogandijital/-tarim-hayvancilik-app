import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/field.dart';

class FieldStorageService {
  static const String _fieldsKey = 'fields_data';

  // Tarlaları kaydet
  static Future<void> saveFields(List<Field> fields) async {
    final prefs = await SharedPreferences.getInstance();
    final fieldsJson = fields.map((field) => field.toJson()).toList();
    await prefs.setString(_fieldsKey, jsonEncode(fieldsJson));
  }

  // Tarlaları yükle
  static Future<List<Field>> loadFields() async {
    final prefs = await SharedPreferences.getInstance();
    final fieldsString = prefs.getString(_fieldsKey);
    
    if (fieldsString == null || fieldsString.isEmpty) {
      return _getDefaultFields(); // İlk açılışta demo veriler
    }
    
    try {
      final List<dynamic> fieldsJson = jsonDecode(fieldsString);
      return fieldsJson.map((json) => Field.fromJson(json)).toList();
    } catch (e) {
      print('Tarla verileri yüklenirken hata: $e');
      return _getDefaultFields();
    }
  }

  // Tek bir tarlayı güncelle
  static Future<void> updateField(Field updatedField) async {
    final fields = await loadFields();
    final index = fields.indexWhere((f) => f.id == updatedField.id);
    if (index != -1) {
      fields[index] = updatedField;
      await saveFields(fields);
    }
  }

  // Tarla ekle
  static Future<void> addField(Field field) async {
    final fields = await loadFields();
    fields.add(field);
    await saveFields(fields);
  }

  // Tarla sil
  static Future<void> deleteField(String fieldId) async {
    final fields = await loadFields();
    fields.removeWhere((f) => f.id == fieldId);
    await saveFields(fields);
  }

  // Tüm verileri temizle (test için)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fieldsKey);
  }

  // Demo veriler (ilk açılışta)
  static List<Field> _getDefaultFields() {
    return [
      Field(
        id: '1',
        name: 'Tarla 1',
        area: 2.5,
        currentCrop: 'Buğday',
        plantingDate: DateTime(2025, 10, 15),
        harvestDate: DateTime(2026, 6, 25),
        tasks: [
          Task(
            id: '1',
            title: 'Toprak hazırlığı',
            isCompleted: true,
            category: TaskCategory.beforePlanting,
          ),
          Task(
            id: '2',
            title: 'Gübreleme',
            isCompleted: true,
            category: TaskCategory.beforePlanting,
          ),
          Task(
            id: '3',
            title: 'Ekim',
            isCompleted: true,
            category: TaskCategory.planting,
          ),
          Task(
            id: '4',
            title: 'İlaçlama',
            dueDate: DateTime(2026, 3, 15),
            isCompleted: false,
            category: TaskCategory.afterPlanting,
          ),
          Task(
            id: '5',
            title: 'Hasat',
            dueDate: DateTime(2026, 6, 25),
            isCompleted: false,
            category: TaskCategory.harvest,
          ),
        ],
      ),
      Field(
        id: '2',
        name: 'Tarla 2',
        area: 1.8,
        currentCrop: 'Mısır',
        plantingDate: DateTime(2025, 5, 10),
        harvestDate: DateTime(2025, 9, 20),
        tasks: [
          Task(
            id: '6',
            title: 'Toprak analizi',
            isCompleted: true,
            category: TaskCategory.beforePlanting,
          ),
          Task(
            id: '7',
            title: 'Ekim',
            isCompleted: true,
            category: TaskCategory.planting,
          ),
          Task(
            id: '8',
            title: 'Sulama sistemi kurulumu',
            dueDate: DateTime(2025, 6, 1),
            isCompleted: false,
            category: TaskCategory.afterPlanting,
          ),
          Task(
            id: '9',
            title: 'Yabani ot temizliği',
            dueDate: DateTime(2025, 7, 15),
            isCompleted: false,
            category: TaskCategory.maintenance,
          ),
          Task(
            id: '10',
            title: 'Hasat',
            dueDate: DateTime(2025, 9, 20),
            isCompleted: false,
            category: TaskCategory.harvest,
          ),
        ],
      ),
      Field(
        id: '3',
        name: 'Tarla 3',
        area: 3.0,
      ),
    ];
  }
}
