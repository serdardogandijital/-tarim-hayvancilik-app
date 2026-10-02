import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarim_hayvancilik_app/models/animal.dart';
import 'package:tarim_hayvancilik_app/models/farm_records.dart';
import 'package:tarim_hayvancilik_app/services/animal_storage_service.dart';
import 'package:tarim_hayvancilik_app/services/farm_record_service.dart';
import 'package:tarim_hayvancilik_app/services/safe_list_store.dart';
import 'package:tarim_hayvancilik_app/services/agenda_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SafeListStore.errors.value = {};
  });
  Animal cow(String id, {List<MilkRecord>? milk, DateTime? birth}) => Animal(
    id: id,
    name: id,
    type: 'İnek',
    breed: '',
    birthDate: birth ?? DateTime(2020),
    milkRecords: milk,
  );
  Future<void> stock() => FarmRecordService.saveStock(
    const StockItem(id: 'feed', name: 'Yem', unit: 'kg', minimumMilli: 2000),
  );
  StockMovement move(String id, int quantity, [int day = 1]) => StockMovement(
    id: id,
    date: DateTime(2025, 1, day),
    quantityMilli: quantity,
  );
  BreedingRecord cycle(
    String id, {
    BreedingStatus status = BreedingStatus.pending,
    List<String> children = const [],
  }) => BreedingRecord(
    id: id,
    inseminationDate: DateTime(2024),
    status: status,
    actualBirthDate: status == BreedingStatus.born ? DateTime(2025) : null,
    offspringIds: children,
  );

  test(
    'Turkish decimals are exact integer units; invalid and excessive precision are rejected',
    () {
      expect(parseUnits('12,50', 2), 1250);
      expect(parseUnits('0,1', 2)! + parseUnits('0,2', 2)!, 30);
      expect(parseUnits('1.005', 3), 1005);
      for (final value in [
        'NaN',
        'Infinity',
        '-1',
        '1e3',
        '1,000.00',
        '1,234',
      ]) {
        expect(parseUnits(value, 2), isNull);
      }
    },
  );
  test(
    'legacy animals and milk survive roundtrip; new fields have compatible defaults',
    () {
      final old =
          cow(
              'a',
              milk: [MilkRecord(date: DateTime(2025), amount: 10)],
            ).toJson()
            ..remove('breedingRecords')
            ..remove('milkTrackingEnabled');
      final animal = Animal.fromJson(old);
      expect(animal.breedingRecords, isEmpty);
      expect(animal.milkTrackingEnabled, isTrue);
      expect(Animal.fromJson(animal.toJson()).milkRecords.single.amount, 10);
      expect(cow('empty').milkTrackingEnabled, isFalse);
    },
  );
  test(
    'stock remains exact after fractional movements and refuses negative history',
    () async {
      await stock();
      await FarmRecordService.saveMovement('feed', move('in', 10000));
      await FarmRecordService.saveMovement('feed', move('out', -4250, 2));
      expect((await FarmRecordService.stocks()).single.balanceMilli, 5750);
      await expectLater(
        FarmRecordService.saveMovement('feed', move('early', -1, 0)),
        throwsA(isA<RecordValidationFailure>()),
      );
      await expectLater(
        FarmRecordService.deleteMovement('feed', 'in'),
        throwsA(isA<RecordValidationFailure>()),
      );
      await expectLater(
        FarmRecordService.saveMovement('feed', move('in', 1000)),
        throwsA(isA<RecordValidationFailure>()),
      );
      expect((await FarmRecordService.stocks()).single.balanceMilli, 5750);
      expect(SafeListStore.errors.value, isEmpty);
    },
  );
  test(
    'concurrent stock withdrawals cannot both spend the same stock',
    () async {
      await stock();
      await FarmRecordService.saveMovement('feed', move('in', 10000));
      final results = await Future.wait(
        ['one', 'two'].map((id) async {
          try {
            await FarmRecordService.saveMovement('feed', move(id, -6000, 2));
            return true;
          } on RecordValidationFailure {
            return false;
          }
        }),
      );
      expect(results.where((success) => success), hasLength(1));
      expect((await FarmRecordService.stocks()).single.balanceMilli, 4000);
    },
  );
  test(
    'editing stock metadata preserves movements and locks the unit after movement',
    () async {
      await stock();
      await FarmRecordService.saveMovement('feed', move('in', 5000));
      await FarmRecordService.saveStock(
        const StockItem(
          id: 'feed',
          name: 'Buzağı yemi',
          unit: 'kg',
          minimumMilli: 6000,
        ),
      );
      final item = (await FarmRecordService.stocks()).single;
      expect(item.balanceMilli, 5000);
      expect(item.low, isTrue);
      await expectLater(
        FarmRecordService.saveStock(item.copyWith(unit: 'adet')),
        throwsA(isA<RecordValidationFailure>()),
      );
    },
  );
  test(
    'corrupt inventory is preserved and cannot be overwritten by adding a card',
    () async {
      SharedPreferences.setMockInitialValues({'farm_stock_v1': 'broken'});
      expect(await FarmRecordService.stocks(), isEmpty);
      await expectLater(stock(), throwsA(isA<StorageFailure>()));
      expect(
        (await SharedPreferences.getInstance()).getString('farm_stock_v1'),
        'broken',
      );
    },
  );
  test(
    'monthly finance sums exact cents and scopes identical animal/field ids separately',
    () async {
      for (final record in [
        FinanceRecord(
          id: '1',
          category: 'Süt',
          income: true,
          date: DateTime(2025, 1),
          amountKurus: 12500,
          ownerType: 'animal',
          ownerId: 'a',
        ),
        FinanceRecord(
          id: '2',
          category: 'Yem',
          income: false,
          date: DateTime(2025, 1, 2),
          amountKurus: 3025,
          ownerType: 'animal',
          ownerId: 'a',
        ),
        FinanceRecord(
          id: '3',
          category: 'Ürün',
          income: true,
          date: DateTime(2025, 1, 3),
          amountKurus: 9999,
          ownerType: 'field',
          ownerId: 'a',
        ),
        FinanceRecord(
          id: '4',
          category: 'Diğer',
          income: true,
          date: DateTime(2025, 2),
          amountKurus: 200,
        ),
      ]) {
        await FarmRecordService.saveFinance(record);
      }
      final jan = FarmRecordService.monthly(
        await FarmRecordService.finances(),
        DateTime(2025, 1),
        ownerType: 'animal',
        ownerId: 'a',
      );
      expect(jan, hasLength(2));
      expect(
        FarmRecordService.total(jan, true) -
            FarmRecordService.total(jan, false),
        9475,
      );
      await FarmRecordService.deleteFinance('2');
      expect(await FarmRecordService.finances(), hasLength(3));
    },
  );
  test('invalid finance amount and future transactions are rejected', () async {
    for (final amount in [0, -100]) {
      await expectLater(
        FarmRecordService.saveFinance(
          FinanceRecord(
            id: 'a',
            category: 'Diğer',
            income: true,
            date: DateTime(2025),
            amountKurus: amount,
          ),
        ),
        throwsA(isA<RecordValidationFailure>()),
      );
    }
    await expectLater(
      FarmRecordService.saveFinance(
        FinanceRecord(
          id: 'b',
          category: 'Diğer',
          income: true,
          date: DateTime.now().add(const Duration(days: 1)),
          amountKurus: 100,
        ),
      ),
      throwsA(isA<RecordValidationFailure>()),
    );
    expect(await FarmRecordService.finances(), isEmpty);
  });
  test(
    'legacy multiple milk entries are aggregated; daily edit replaces total and zero is a record',
    () async {
      final date = DateTime(2025, 1, 2);
      await AnimalStorageService.addAnimal(
        cow(
          'a',
          milk: [
            MilkRecord(date: date, amount: 5),
            MilkRecord(date: date.add(const Duration(hours: 12)), amount: 6),
          ],
        ),
      );
      expect(
        FarmRecordService.dailyMilk(
          (await AnimalStorageService.loadAnimals()).single,
        )[date],
        11,
      );
      await FarmRecordService.saveMilk('a', date, 0);
      final animals = await AnimalStorageService.loadAnimals();
      expect(animals.single.milkRecords, hasLength(1));
      expect(FarmRecordService.missingMilk(animals, date), isEmpty);
      expect(
        FarmRecordService.missingMilk(
          animals,
          date.add(const Duration(days: 1)),
        ),
        hasLength(1),
      );
      await FarmRecordService.milkTracking('a', false);
      expect(
        (await AnimalStorageService.loadAnimals()).single.milkRecords,
        hasLength(1),
      );
      expect(
        FarmRecordService.missingMilk(
          await AnimalStorageService.loadAnimals(),
          date.add(const Duration(days: 1)),
        ),
        isEmpty,
      );
    },
  );
  test(
    'moving a milk record removes its old day and refuses collision with another recorded day',
    () async {
      await AnimalStorageService.addAnimal(cow('a'));
      await FarmRecordService.saveMilk('a', DateTime(2025, 1, 1), 4);
      await FarmRecordService.saveMilk(
        'a',
        DateTime(2025, 1, 2),
        6,
        previousDate: DateTime(2025, 1, 1),
      );
      expect(
        (await AnimalStorageService.loadAnimals())
            .single
            .milkRecords
            .single
            .date,
        DateTime(2025, 1, 2),
      );
      await FarmRecordService.saveMilk('a', DateTime(2025, 1, 3), 7);
      await expectLater(
        FarmRecordService.saveMilk(
          'a',
          DateTime(2025, 1, 3),
          9,
          previousDate: DateTime(2025, 1, 2),
        ),
        throwsA(isA<RecordValidationFailure>()),
      );
      expect(
        (await AnimalStorageService.loadAnimals()).single.milkRecords,
        hasLength(2),
      );
    },
  );
  test(
    'milk and reproduction updates preserve one another under concurrency',
    () async {
      await AnimalStorageService.addAnimal(cow('a'));
      await Future.wait([
        FarmRecordService.saveMilk('a', DateTime(2025), 12.5),
        FarmRecordService.saveBreeding('a', cycle('one')),
      ]);
      final a = (await AnimalStorageService.loadAnimals()).single;
      expect(a.milkRecords.single.amount, 12.5);
      expect(a.breedingRecords, hasLength(1));
      expect(
        Animal.fromJson(
          jsonDecode(jsonEncode(a.toJson())),
        ).breedingRecords.single.id,
        'one',
      );
    },
  );
  test(
    'only one active breeding cycle; completed cycle allows next one',
    () async {
      await AnimalStorageService.addAnimal(cow('a'));
      await FarmRecordService.saveBreeding('a', cycle('one'));
      await expectLater(
        FarmRecordService.saveBreeding('a', cycle('two')),
        throwsA(isA<RecordValidationFailure>()),
      );
      await FarmRecordService.saveBreeding(
        'a',
        cycle('one', status: BreedingStatus.notPregnant),
      );
      await FarmRecordService.saveBreeding('a', cycle('two'));
      expect(
        (await AnimalStorageService.loadAnimals()).single.breedingRecords,
        hasLength(2),
      );
    },
  );
  test(
    'birth links must reference actual same-day offspring and cannot assign two mothers',
    () async {
      await AnimalStorageService.addAnimal(cow('mother'));
      await AnimalStorageService.addAnimal(cow('other'));
      await AnimalStorageService.addAnimal(cow('calf', birth: DateTime(2025)));
      await FarmRecordService.saveBreeding(
        'mother',
        cycle('born', status: BreedingStatus.born, children: ['calf']),
      );
      await expectLater(
        FarmRecordService.saveBreeding(
          'other',
          cycle('born2', status: BreedingStatus.born, children: ['calf']),
        ),
        throwsA(isA<RecordValidationFailure>()),
      );
      final mother = (await AnimalStorageService.loadAnimals()).firstWhere(
        (a) => a.id == 'mother',
      );
      expect(mother.latestBirthDate, DateTime(2025));
      await FarmRecordService.deleteBreeding('mother', 'born');
      expect(
        (await AnimalStorageService.loadAnimals())
            .firstWhere((a) => a.id == 'mother')
            .latestBirthDate,
        isNull,
      );
      expect(await AnimalStorageService.loadAnimals(), hasLength(3));
    },
  );
  test(
    'agenda includes active check/birth dates and excludes closed history',
    () {
      final now = DateTime(2025, 1, 1);
      final animal = cow('a').copyWith(
        breedingRecords: [
          BreedingRecord(
            id: 'pending',
            inseminationDate: DateTime(2024),
            checkDate: now,
          ),
          BreedingRecord(
            id: 'pregnant',
            inseminationDate: DateTime(2024),
            status: BreedingStatus.pregnant,
            expectedBirthDate: now.add(const Duration(days: 3)),
          ),
          BreedingRecord(
            id: 'closed',
            inseminationDate: DateTime(2024),
            status: BreedingStatus.notPregnant,
            checkDate: now,
          ),
        ],
      );
      expect(AgendaService.build([], [animal], now: now).map((i) => i.title), [
        'Gebelik kontrolü',
        'Beklenen doğum',
      ]);
    },
  );
}
