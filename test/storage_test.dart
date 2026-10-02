import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarim_hayvancilik_app/models/animal.dart';
import 'package:tarim_hayvancilik_app/models/field.dart';
import 'package:tarim_hayvancilik_app/services/animal_storage_service.dart';
import 'package:tarim_hayvancilik_app/services/field_storage_service.dart';
import 'package:tarim_hayvancilik_app/services/plant_storage_service.dart';
import 'package:tarim_hayvancilik_app/services/safe_list_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SafeListStore.errors.value = {};
  });

  test('new installations have no fictitious fields', () async {
    expect(await FieldStorageService.loadFields(), isEmpty);
  });

  test(
    'concurrent additions preserve all records and a previous snapshot',
    () async {
      await Future.wait(
        List.generate(
          20,
          (i) => FieldStorageService.addField(
            Field(id: '$i', name: 'Tarla $i', area: 2.5),
          ),
        ),
      );
      final records = await FieldStorageService.loadFields();
      expect(records.map((e) => e.id).toSet().length, 20);
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('fields_data_backup')!), hasLength(19));
    },
  );

  test(
    'malformed animal data is reported and never replaced on mutation',
    () async {
      const damaged = '[{"id":"legacy","birthDate":"invalid"}]';
      SharedPreferences.setMockInitialValues({'animals_data': damaged});
      expect(await AnimalStorageService.loadAnimals(), isEmpty);
      expect(SafeListStore.errors.value, contains('animals_data'));
      await expectLater(
        AnimalStorageService.addAnimal(
          Animal(
            id: 'new',
            name: 'Yeni',
            type: 'İnek',
            breed: 'Simental',
            birthDate: DateTime(2024),
          ),
        ),
        throwsA(isA<StorageFailure>()),
      );
      expect(
        (await SharedPreferences.getInstance()).getString('animals_data'),
        damaged,
      );
      await expectLater(
        AnimalStorageService.saveAnimals([]),
        throwsA(isA<StorageFailure>()),
      );
    },
  );

  test('damaged plant history cannot be silently erased by deleting', () async {
    SharedPreferences.setMockInitialValues({'plant_analyses': 'broken'});
    expect(await PlantStorageService.loadAnalyses(), isEmpty);
    await expectLater(
      PlantStorageService.deleteAnalysis('1'),
      throwsA(isA<StorageFailure>()),
    );
    expect(
      (await SharedPreferences.getInstance()).getString('plant_analyses'),
      'broken',
    );
  });

  test('existing schema survives read, update and delete', () async {
    final field = Field(
      id: 'legacy',
      name: 'Eski tarla',
      area: 5,
      tasks: [
        Task(
          id: 'task',
          title: 'Sulama',
          isCompleted: true,
          category: TaskCategory.maintenance,
        ),
      ],
    );
    SharedPreferences.setMockInitialValues({
      'fields_data': jsonEncode([field.toJson()]),
    });
    await FieldStorageService.updateField(field.copyWith(name: 'Yeni ad'));
    final loaded = (await FieldStorageService.loadFields()).single;
    expect(loaded.name, 'Yeni ad');
    expect(loaded.tasks.single.isCompleted, isTrue);
    await FieldStorageService.deleteField('legacy');
    expect(await FieldStorageService.loadFields(), isEmpty);
  });
}
