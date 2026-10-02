import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarim_hayvancilik_app/main.dart';
import 'package:tarim_hayvancilik_app/services/field_storage_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'field entry with Turkish decimals persists and updates dashboard',
    (tester) async {
      await initializeDateFormatting('tr_TR');
      await tester.pumpWidget(const TarimHayvancilikApp());
      await tester.pumpAndSettle();
      final name = 'Simülatör Test ${DateTime.now().millisecondsSinceEpoch}';
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Tarım'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tarla Ekle'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), name);
      await tester.enterText(find.byType(TextFormField).at(1), '2,5');
      await tester.enterText(find.byType(TextFormField).at(2), 'Buğday');
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      final records = await FieldStorageService.loadFields();
      final saved = records.singleWhere((item) => item.name == name);
      expect(saved.area, 2.5);
      expect(saved.currentCrop, 'Buğday');
      expect(find.text(name), findsWidgets);
      expect(tester.takeException(), isNull);

      // Recreate the widget tree without clearing native storage.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const TarimHayvancilikApp());
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Tarım'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(name), findsWidgets);
      expect(tester.takeException(), isNull);
      // Remove only the record created by this test.
      await FieldStorageService.deleteField(saved.id);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
