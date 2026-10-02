import '../models/animal.dart';
import 'safe_list_store.dart';

class AnimalStorageService {
  static final _store = SafeListStore<Animal>(
    'animals_data',
    Animal.fromJson,
    (value) => value.toJson(),
  );
  static Future<List<Animal>> loadAnimals() => _store.load();
  static Future<void> saveAnimals(List<Animal> records) =>
      _store.replace(records);
  static Future<void> addAnimal(Animal record) => _store.change((records) {
    if (records.any((item) => item.id == record.id)) {
      throw StateError('Duplicate id');
    }
    records.add(record);
  });
  static Future<void> updateAnimal(Animal record) => _store.change((records) {
    final index = records.indexWhere((item) => item.id == record.id);
    if (index == -1) throw StateError('Missing record');
    records[index] = record;
  });
  static Future<void> changeAnimals(void Function(List<Animal>) update) =>
      _store.change(update);
  static Future<void> mutateAnimal(String id, Animal Function(Animal) update) =>
      _store.change((records) {
        final index = records.indexWhere((a) => a.id == id);
        if (index < 0) {
          throw const RecordValidationFailure(
            'Hayvan kaydı artık mevcut değil.',
          );
        }
        records[index] = update(records[index]);
      });
  static Future<void> deleteAnimal(String id) =>
      _store.change((records) => records.removeWhere((item) => item.id == id));
  static Future<void> clearAllData() => _store.replace([]);
}
