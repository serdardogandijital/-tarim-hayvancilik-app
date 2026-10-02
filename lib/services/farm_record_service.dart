import '../models/animal.dart';
import '../models/farm_records.dart';
import 'animal_storage_service.dart';
import 'safe_list_store.dart';

class FarmRecordService {
  static final _stock = SafeListStore<StockItem>(
    'farm_stock_v1',
    StockItem.fromJson,
    (v) => v.toJson(),
  );
  static final _finance = SafeListStore<FinanceRecord>(
    'farm_finance_v1',
    FinanceRecord.fromJson,
    (v) => v.toJson(),
  );
  static Future<List<StockItem>> stocks() => _stock.load();
  static Future<List<FinanceRecord>> finances() => _finance.load();
  static void require(bool valid, String message) {
    if (!valid) throw RecordValidationFailure(message);
  }

  static Future<void> saveStock(StockItem item) => _stock.change((items) {
    require(
      item.name.trim().isNotEmpty && item.minimumMilli >= 0,
      'Ürün adı ve geçerli stok eşiği girin.',
    );
    require(
      ['kg', 'litre', 'adet', 'çuval', 'balya'].contains(item.unit),
      'Geçerli birim seçin.',
    );
    require(
      !items.any(
        (i) =>
            i.id != item.id &&
            i.name.trim().toLowerCase() == item.name.trim().toLowerCase(),
      ),
      'Bu isimde bir stok kartı zaten var.',
    );
    final index = items.indexWhere((i) => i.id == item.id);
    if (index < 0) {
      items.add(item.copyWith(movements: []));
    } else {
      final current = items[index];
      require(
        current.movements.isEmpty || item.unit == current.unit,
        'Hareketi olan ürünün birimi değiştirilemez.',
      );
      items[index] = current.copyWith(
        name: item.name.trim(),
        unit: item.unit,
        minimumMilli: item.minimumMilli,
      );
    }
  });
  static void _validateMovements(List<StockMovement> movements) {
    final indexed = movements.asMap().entries.toList()
      ..sort((a, b) {
        final date = a.value.date.compareTo(b.value.date);
        return date == 0 ? a.key.compareTo(b.key) : date;
      });
    var balance = 0;
    for (final entry in indexed) {
      final m = entry.value;
      require(
        m.quantityMilli != 0 &&
            !dayOnly(m.date).isAfter(dayOnly(DateTime.now())),
        'Geçerli miktar ve geçmiş/bugün tarihi girin.',
      );
      balance += m.quantityMilli;
      require(
        balance >= 0,
        'Bu işlem stok geçmişinde eksi bakiye oluşturur. Önce girişleri kontrol edin.',
      );
    }
  }

  static Future<void> saveMovement(String stockId, StockMovement movement) =>
      _stock.change((items) {
        final index = items.indexWhere((i) => i.id == stockId);
        require(index >= 0, 'Stok kartı bulunamadı.');
        final moves = [...items[index].movements];
        final pos = moves.indexWhere((m) => m.id == movement.id);
        if (pos < 0) {
          moves.add(movement);
        } else {
          moves[pos] = movement;
        }
        _validateMovements(moves);
        items[index] = items[index].copyWith(movements: moves);
      });
  static Future<void> deleteMovement(String stockId, String id) =>
      _stock.change((items) {
        final index = items.indexWhere((i) => i.id == stockId);
        require(index >= 0, 'Stok kartı bulunamadı.');
        final moves = items[index].movements.where((m) => m.id != id).toList();
        _validateMovements(moves);
        items[index] = items[index].copyWith(movements: moves);
      });
  static Future<void> deleteStock(String id) =>
      _stock.change((items) => items.removeWhere((i) => i.id == id));
  static Future<void> saveFinance(FinanceRecord entry) =>
      _finance.change((records) {
        require(
          entry.amountKurus > 0 && entry.category.trim().isNotEmpty,
          'Pozitif tutar ve kategori girin.',
        );
        require(
          !dayOnly(entry.date).isAfter(dayOnly(DateTime.now())),
          'Gerçekleşen işlem için gelecek tarih seçilemez.',
        );
        require(
          (entry.ownerType == null && entry.ownerId == null) ||
              (['animal', 'field'].contains(entry.ownerType) &&
                  entry.ownerId != null),
          'Kayıt bağlantısı geçersiz.',
        );
        final index = records.indexWhere((r) => r.id == entry.id);
        if (index < 0) {
          records.add(entry);
        } else {
          records[index] = entry;
        }
      });
  static Future<void> deleteFinance(String id) =>
      _finance.change((records) => records.removeWhere((r) => r.id == id));
  static List<FinanceRecord> monthly(
    List<FinanceRecord> entries,
    DateTime month, {
    String? ownerType,
    String? ownerId,
  }) => entries
      .where(
        (e) =>
            e.date.year == month.year &&
            e.date.month == month.month &&
            (ownerId == null ||
                (e.ownerId == ownerId && e.ownerType == ownerType)),
      )
      .toList();
  static int total(List<FinanceRecord> entries, bool income) => entries
      .where((e) => e.income == income)
      .fold(0, (s, e) => s + e.amountKurus);

  static Future<void> milkTracking(String animalId, bool enabled) =>
      AnimalStorageService.mutateAnimal(
        animalId,
        (animal) => animal.copyWith(milkTrackingEnabled: enabled),
      );
  static Future<void> saveMilk(
    String animalId,
    DateTime date,
    double litres, {
    DateTime? previousDate,
  }) => AnimalStorageService.mutateAnimal(animalId, (animal) {
    require(
      litres.isFinite && litres >= 0,
      'Süt miktarı sıfır veya pozitif olmalı.',
    );
    require(
      !dayOnly(date).isAfter(dayOnly(DateTime.now())) &&
          !dayOnly(date).isBefore(dayOnly(animal.birthDate)),
      'Tarih doğumdan önce veya gelecekte olamaz.',
    );
    require(
      previousDate == null ||
          sameDay(previousDate, date) ||
          !animal.milkRecords.any((m) => sameDay(m.date, date)),
      'Hedef günde zaten süt kaydı var; o kaydı düzenleyin.',
    );
    return animal.copyWith(
      milkTrackingEnabled: true,
      milkRecords: [
        ...animal.milkRecords.where(
          (m) =>
              !sameDay(m.date, date) &&
              (previousDate == null || !sameDay(m.date, previousDate)),
        ),
        MilkRecord(date: dayOnly(date), amount: litres),
      ],
    );
  });
  static Future<void> deleteMilk(String animalId, DateTime date) =>
      AnimalStorageService.mutateAnimal(
        animalId,
        (animal) => animal.copyWith(
          milkRecords: animal.milkRecords
              .where((m) => !sameDay(m.date, date))
              .toList(),
        ),
      );
  static Map<DateTime, double> dailyMilk(Animal animal) {
    final result = <DateTime, double>{};
    for (final r in animal.milkRecords) {
      result.update(
        dayOnly(r.date),
        (v) => v + r.amount,
        ifAbsent: () => r.amount,
      );
    }
    return result;
  }

  static List<Animal> missingMilk(List<Animal> animals, DateTime date) =>
      animals
          .where(
            (a) =>
                a.milkTrackingEnabled &&
                !a.milkRecords.any((m) => sameDay(m.date, date)),
          )
          .toList();
  static double milkTotal(List<Animal> animals, DateTime date) =>
      animals.fold(0, (sum, a) => sum + (dailyMilk(a)[dayOnly(date)] ?? 0));
  static Future<void> saveBreeding(String animalId, BreedingRecord record) =>
      AnimalStorageService.changeAnimals((animals) {
        final index = animals.indexWhere((a) => a.id == animalId);
        require(index >= 0, 'Hayvan kaydı bulunamadı.');
        final animal = animals[index];
        final today = dayOnly(DateTime.now());
        final start = dayOnly(record.inseminationDate);
        require(
          !start.isAfter(today) && !start.isBefore(dayOnly(animal.birthDate)),
          'Tohumlama tarihi doğumdan önce veya gelecekte olamaz.',
        );
        for (final date in [
          record.checkDate,
          record.expectedBirthDate,
          record.actualBirthDate,
        ]) {
          require(
            date == null || !dayOnly(date).isBefore(start),
            'Takip tarihleri tohumlama tarihinden önce olamaz.',
          );
        }
        require(
          record.status != BreedingStatus.pregnant ||
              record.expectedBirthDate != null,
          'Beklenen doğum tarihini girin.',
        );
        require(
          record.status != BreedingStatus.born ||
              record.actualBirthDate != null,
          'Gerçekleşen doğum tarihini girin.',
        );
        require(
          record.actualBirthDate == null ||
              !dayOnly(record.actualBirthDate!).isAfter(today),
          'Gerçekleşen doğum tarihi gelecekte olamaz.',
        );
        require(
          record.status == BreedingStatus.born ||
              (record.actualBirthDate == null && record.offspringIds.isEmpty),
          'Doğum bilgisi yalnız gerçekleşmiş doğuma eklenebilir.',
        );
        require(
          !record.status.active ||
              !animal.breedingRecords.any(
                (r) => r.id != record.id && r.status.active,
              ),
          'Önce açık üreme kaydının sonucunu güncelleyin.',
        );
        for (final child in record.offspringIds) {
          require(
            child != animalId && animals.any((a) => a.id == child),
            'Geçerli bir yavru kaydı seçin.',
          );
          require(
            !animals.any(
              (a) => a.breedingRecords.any(
                (r) =>
                    !(a.id == animalId && r.id == record.id) &&
                    r.offspringIds.contains(child),
              ),
            ),
            'Bu yavru başka bir doğum kaydına bağlı.',
          );
          final calf = animals.firstWhere((a) => a.id == child);
          require(
            sameDay(calf.birthDate, record.actualBirthDate!),
            'Yavrunun doğum tarihi, doğum kaydının tarihiyle aynı olmalı.',
          );
        }
        final records = [...animal.breedingRecords];
        final pos = records.indexWhere((r) => r.id == record.id);
        if (pos < 0) {
          records.add(record);
        } else {
          records[pos] = record;
        }
        animals[index] = animal.copyWith(breedingRecords: records);
      });
  static Future<void> deleteBreeding(String animalId, String id) =>
      AnimalStorageService.mutateAnimal(
        animalId,
        (animal) => animal.copyWith(
          breedingRecords: animal.breedingRecords
              .where((r) => r.id != id)
              .toList(),
        ),
      );
}
