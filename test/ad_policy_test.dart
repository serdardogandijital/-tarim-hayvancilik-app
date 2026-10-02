import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarim_hayvancilik_app/main.dart' as app;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'non-mobile startup and navigation do not contact the mobile ads SDK',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      var adMessages = 0;
      const channel = 'plugins.flutter.io/google_mobile_ads';
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(channel, (
        _,
      ) async {
        adMessages++;
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          channel,
          null,
        ),
      );

      app.main();
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.pump(const Duration(seconds: 16));
      await tester.pump(const Duration(minutes: 5));
      for (final title in ['Tarım', 'Hayvancılık', 'Ana Sayfa']) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(title),
          ),
        );
        await tester.pumpAndSettle();
      }
      expect(adMessages, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
