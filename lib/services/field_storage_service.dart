import '../models/field.dart';
import 'safe_list_store.dart';

class FieldStorageService {
  static final _store = SafeListStore<Field>(
    'fields_data',
    Field.fromJson,
    (value) => value.toJson(),
  );
  static Future<List<Field>> loadFields() => _store.load();
  static Future<void> saveFields(List<Field> records) =>
      _store.replace(records);
  static Future<void> addField(Field record) => _store.change((records) {
    if (records.any((item) => item.id == record.id))
      throw StateError('Duplicate id');
    records.add(record);
  });
  static Future<void> updateField(Field record) => _store.change((records) {
    final index = records.indexWhere((item) => item.id == record.id);
    if (index == -1) throw StateError('Missing record');
    records[index] = record;
  });
  static Future<void> deleteField(String id) =>
      _store.change((records) => records.removeWhere((item) => item.id == id));
  static Future<void> clearAllData() => _store.replace([]);
}
