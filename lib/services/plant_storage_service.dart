import '../models/plant_analysis.dart';
import 'safe_list_store.dart';

class PlantStorageService {
  static final _store = SafeListStore<PlantAnalysis>(
    'plant_analyses',
    PlantAnalysis.fromJson,
    (value) => value.toJson(),
  );
  static Future<List<PlantAnalysis>> loadAnalyses() => _store.load();
  static Future<void> saveAnalysis(PlantAnalysis analysis) =>
      _store.change((records) {
        records.removeWhere((item) => item.id == analysis.id);
        records.insert(0, analysis);
      });
  static Future<void> deleteAnalysis(String id) =>
      _store.change((records) => records.removeWhere((item) => item.id == id));
  static Future<void> clearAll() => _store.replace([]);
}
