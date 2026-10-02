import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarim_hayvancilik_app/models/animal.dart';
import 'package:tarim_hayvancilik_app/models/farm_records.dart';
import 'package:tarim_hayvancilik_app/services/animal_storage_service.dart';
import 'package:tarim_hayvancilik_app/services/farm_record_service.dart';
import 'package:tarim_hayvancilik_app/services/safe_list_store.dart';
import 'package:tarim_hayvancilik_app/screens/animal_tracking_screen.dart';
import 'package:tarim_hayvancilik_app/screens/farm_records_screen.dart';
import 'package:tarim_hayvancilik_app/widgets/farm_summary_card.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'animals_data': jsonEncode([
        Animal(
          id: 'cow',
          name: 'Sarı kız',
          type: 'İnek',
          breed: 'Simental',
          birthDate: DateTime(2020),
          milkTrackingEnabled: true,
        ).toJson(),
      ]),
    });
    SafeListStore.errors.value = {};
    await initializeDateFormatting('tr_TR');
  });
  Future<void> open(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'milk form persists Turkish decimal, edits daily total, shows graph and preserves tracking toggle',
    (tester) async {
      await open(tester, const AnimalTrackingScreen(animalId: 'cow'));
      await tap(tester, find.text('Süt kaydı ekle'));
      await tester.enterText(find.byKey(const ValueKey('amount')), '12,5');
      await tap(tester, find.text('Kaydet'));
      expect(
        (await AnimalStorageService.loadAnimals())
            .single
            .milkRecords
            .single
            .amount,
        12.5,
      );
      expect(find.text('Son 7 gün: 12.5 litre'), findsOneWidget);
      await tap(tester, find.text('Süt kaydı ekle'));
      await tester.enterText(find.byKey(const ValueKey('amount')), '0');
      await tap(tester, find.text('Kaydet'));
      expect(
        (await AnimalStorageService.loadAnimals())
            .single
            .milkRecords
            .single
            .amount,
        0,
      );
      expect(find.textContaining('1/7 gün kayıtlı'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'stock receipt works, invalid withdrawal is visible and cannot reduce inventory',
    (tester) async {
      await FarmRecordService.saveStock(
        const StockItem(id: 'feed', name: 'Buzağı yemi', unit: 'kg'),
      );
      await open(tester, const StockDetailScreen(id: 'feed'));
      await tap(tester, find.text('Stok hareketi ekle'));
      await tester.enterText(find.byKey(const ValueKey('amount')), '25,5');
      await tap(tester, find.text('Kaydet'));
      expect(find.text('Kalan: 25,500 kg'), findsOneWidget);
      await tap(tester, find.text('Stok hareketi ekle'));
      await tap(tester, find.byKey(const ValueKey('kind-in')));
      await tap(tester, find.text('Çıkış / kullanım').last);
      await tester.enterText(find.byKey(const ValueKey('amount')), '30');
      await tap(tester, find.text('Kaydet'));
      expect(find.byKey(const ValueKey('record-error')), findsOneWidget);
      expect((await FarmRecordService.stocks()).single.balanceMilli, 25500);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'finance entered from animal context persists link and exact amount',
    (tester) async {
      await open(
        tester,
        const FarmRecordsScreen(
          initialTab: 1,
          ownerType: 'animal',
          ownerId: 'cow',
          ownerName: 'Sarı kız',
        ),
      );
      await tap(tester, find.text('Gelir / gider ekle'));
      await tester.enterText(find.byKey(const ValueKey('amount')), '123,45');
      await tap(tester, find.text('Kaydet'));
      final saved = (await FarmRecordService.finances()).single;
      expect(saved.amountKurus, 12345);
      expect(saved.ownerType, 'animal');
      expect(saved.ownerId, 'cow');
      expect(find.text('Kayıtlı gider: 123,45 ₺'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'breeding form stores pending cycle and editing outcome retains single history entry',
    (tester) async {
      await open(
        tester,
        const AnimalTrackingScreen(animalId: 'cow', initialTab: 1),
      );
      await tap(tester, find.text('Tohumlama kaydı ekle'));
      await tap(tester, find.text('Kaydet'));
      expect(
        (await AnimalStorageService.loadAnimals())
            .single
            .breedingRecords
            .single
            .status,
        BreedingStatus.pending,
      );
      await tap(tester, find.text('Düzenle'));
      await tap(tester, find.byKey(const ValueKey('status-pending')));
      await tap(tester, find.text('Gebe değil').last);
      await tap(tester, find.text('Kaydet'));
      expect(
        (await AnimalStorageService.loadAnimals())
            .single
            .breedingRecords
            .single
            .status,
        BreedingStatus.notPregnant,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'daily summary reacts to milk and low-stock changes without treating zero as missing',
    (tester) async {
      await open(
        tester,
        const Scaffold(body: SingleChildScrollView(child: FarmSummaryCard())),
      );
      expect(find.textContaining('1 hayvanda süt kaydı eksik'), findsOneWidget);
      await FarmRecordService.saveMilk('cow', DateTime.now(), 0);
      await FarmRecordService.saveStock(
        const StockItem(
          id: 'feed',
          name: 'Yem',
          unit: 'kg',
          minimumMilli: 1000,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0.0 L'), findsOneWidget);
      expect(find.text('Günlük kayıtlar tamam'), findsOneWidget);
      expect(find.text('1 stok uyarı eşiğinde'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
