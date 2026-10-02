import 'package:flutter_test/flutter_test.dart';
import 'package:tarim_hayvancilik_app/models/animal.dart';
import 'package:tarim_hayvancilik_app/models/field.dart';
import 'package:tarim_hayvancilik_app/services/agenda_service.dart';

void main() {
  test(
    'today is included even after midnight; completed and distant tasks are omitted',
    () {
      final now = DateTime(2026, 10, 2, 18);
      final field = Field(
        id: '1',
        name: 'Bahçe',
        area: 2,
        tasks: [
          Task(
            id: '1',
            title: 'Bugün',
            category: TaskCategory.maintenance,
            dueDate: DateTime(2026, 10, 2),
          ),
          Task(
            id: '2',
            title: 'Gecikmiş',
            category: TaskCategory.maintenance,
            dueDate: DateTime(2026, 10, 1),
          ),
          Task(
            id: '3',
            title: 'Tamamlandı',
            category: TaskCategory.maintenance,
            dueDate: now,
            isCompleted: true,
          ),
          Task(
            id: '4',
            title: 'Uzak',
            category: TaskCategory.maintenance,
            dueDate: DateTime(2026, 10, 10),
          ),
        ],
      );
      final animal = Animal(
        id: 'a',
        name: 'Sarı kız',
        type: 'İnek',
        breed: 'Simental',
        birthDate: DateTime(2024),
        nextHeatDate: DateTime(2026, 10, 9),
        vaccines: [
          VaccineRecord(
            name: 'Kontrol',
            date: DateTime(2025),
            nextDate: DateTime(2026, 10, 3),
          ),
        ],
      );
      final items = AgendaService.build([field], [animal], now: now);
      expect(items.map((e) => e.title), [
        'Gecikmiş',
        'Bugün',
        'Aşı: Kontrol',
        'Kızgınlık takibi',
      ]);
      expect(items[1].daysFrom(now), 0);
      expect(items.last.daysFrom(now), 7);
      expect(items.last.tab, 2);
    },
  );
}
