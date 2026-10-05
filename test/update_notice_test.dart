import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarim_hayvancilik_app/main.dart' as app;
import 'package:tarim_hayvancilik_app/services/update_notice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a new installation does not get an update notice', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await UpdateNotice.shouldShowAutomatically(), isFalse);
    expect(await UpdateNotice.shouldShowAutomatically(), isFalse);
  });

  testWidgets('an existing user sees the notice once and can reopen it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'fields_initialized': true});
    FlutterSecureStorage.setMockInitialValues({});

    app.main();
    await tester.pumpAndSettle();
    expect(find.text('Çiftçi+ yenilikleri'), findsOneWidget);
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.text('Çiftçi+ yenilikleri'), findsNothing);
    expect(await UpdateNotice.shouldShowAutomatically(), isFalse);

    await tester.tap(find.byTooltip('Yenilikler'));
    await tester.pumpAndSettle();
    expect(find.text('Çiftçi+ yenilikleri'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
