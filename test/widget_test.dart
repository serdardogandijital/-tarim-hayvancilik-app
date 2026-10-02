import 'package:tarim_hayvancilik_app/models/farm_records.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarim_hayvancilik_app/main.dart';
import 'package:tarim_hayvancilik_app/models/animal.dart';
import 'package:tarim_hayvancilik_app/screens/add_animal_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('tr_TR');
  });

  testWidgets('cold start and all three tabs render without an exception', (
    tester,
  ) async {
    await tester.pumpWidget(const TarimHayvancilikApp());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
    for (final title in ['Tarım', 'Hayvancılık', 'Ana Sayfa']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(title),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('editing general animal information preserves tracking data', (
    tester,
  ) async {
    final animal = Animal(
      id: 'existing',
      name: 'Sarı kız',
      type: 'İnek',
      breed: 'Simental',
      birthDate: DateTime(2024),
      breedingRecords: [
        BreedingRecord(id: 'cycle', inseminationDate: DateTime(2025)),
      ],
      milkTrackingEnabled: true,
      dailyFeedAmount: 10,
      monthlyFeedCost: 2500,
      vaccines: [VaccineRecord(name: 'Aşı kaydı', date: DateTime(2026))],
      milkRecords: [MilkRecord(date: DateTime(2026), amount: 12)],
    );
    Animal? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await Navigator.of(context).push<Animal>(
                  MaterialPageRoute(
                    builder: (_) => AddAnimalScreen(animal: animal),
                  ),
                );
              },
              child: const Text('Düzenle'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Güncelle'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();
    expect(saved, isNotNull);
    expect(saved!.vaccines.single.name, 'Aşı kaydı');
    expect(saved!.milkRecords.single.amount, 12);
    expect(saved!.breedingRecords.single.id, 'cycle');
    expect(saved!.milkTrackingEnabled, isTrue);
    expect(saved!.dailyFeedAmount, 10);
    expect(saved!.monthlyFeedCost, 2500);
  });
}
