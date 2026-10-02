import '../models/farm_records.dart';
import '../models/animal.dart';
import '../models/field.dart';

class AgendaItem {
  const AgendaItem({
    required this.title,
    required this.owner,
    required this.date,
    required this.tab,
  });
  final String title;
  final String owner;
  final DateTime date;
  final int tab;

  int daysFrom(DateTime now) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
}

class AgendaService {
  static List<AgendaItem> build(
    List<Field> fields,
    List<Animal> animals, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final items = <AgendaItem>[];
    void add(String title, String owner, DateTime? date, int tab) {
      if (date == null) return;
      final item = AgendaItem(title: title, owner: owner, date: date, tab: tab);
      if (item.daysFrom(today) <= 7) items.add(item);
    }

    for (final field in fields) {
      for (final task in field.tasks) {
        if (!task.isCompleted) add(task.title, field.name, task.dueDate, 0);
      }
    }
    for (final animal in animals) {
      add('Kızgınlık takibi', animal.name, animal.nextHeatDate, 2);
      for (final record in animal.breedingRecords) {
        if (record.status == BreedingStatus.pending) {
          add('Gebelik kontrolü', animal.name, record.checkDate, 2);
        }
        if (record.status == BreedingStatus.pregnant) {
          add('Beklenen doğum', animal.name, record.expectedBirthDate, 2);
        }
      }
      for (final vaccine in animal.vaccines) {
        add('Aşı: ${vaccine.name}', animal.name, vaccine.nextDate, 2);
      }
    }
    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }
}
