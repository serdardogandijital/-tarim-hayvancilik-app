import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_analysis.dart';

class PlantStorageService {
  static const String _storageKey = 'plant_analyses';

  static Future<List<PlantAnalysis>> loadAnalyses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => PlantAnalysis.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveAnalysis(PlantAnalysis analysis) async {
    try {
      final analyses = await loadAnalyses();
      analyses.insert(0, analysis);
      
      if (analyses.length > 50) {
        analyses.removeRange(50, analyses.length);
      }

      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(analyses.map((a) => a.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      throw Exception('Analiz kaydedilemedi: ${e.toString()}');
    }
  }

  static Future<void> deleteAnalysis(String id) async {
    try {
      final analyses = await loadAnalyses();
      analyses.removeWhere((analysis) => analysis.id == id);

      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(analyses.map((a) => a.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      throw Exception('Analiz silinemedi: ${e.toString()}');
    }
  }

  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      throw Exception('Analizler temizlenemedi: ${e.toString()}');
    }
  }
}
