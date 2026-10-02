import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarim_hayvancilik_app/services/analysis_credits.dart';
import 'package:tarim_hayvancilik_app/services/ad_service.dart';
import 'package:tarim_hayvancilik_app/widgets/analysis_credits_card.dart';

class DialogGateway implements RewardedGateway {
  int shows = 0;
  @override
  Future<void> show(Future<void> Function() earned) async {
    shows++;
    await earned();
  }
}

void main() {
  testWidgets(
    'opening and declining do not show an ad; explicit opt-in grants one and updates balance',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? saved;
      final credits = AnalysisCredits(
        read: () async => saved,
        write: (v) async => saved = v,
      );
      await credits.refresh();
      final gateway = DialogGateway();
      final rewards = RewardCredits(credits, gateway);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showCreditsDialog(context, rewards: rewards),
                child: const Text('Haklar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Haklar'));
      await tester.pumpAndSettle();
      expect(find.text('3 analiz hakkın var'), findsOneWidget);
      expect(gateway.shows, 0);
      await tester.tap(find.text('Şimdi değil'));
      await tester.pumpAndSettle();
      expect(gateway.shows, 0);
      await tester.tap(find.text('Haklar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reklam izle · +1 hak'));
      await tester.pumpAndSettle();
      expect(gateway.shows, 1);
      expect(find.text('4 analiz hakkın var'), findsOneWidget);
      expect(find.text('1 analiz hakkı eklendi.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
