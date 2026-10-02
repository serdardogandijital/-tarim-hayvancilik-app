import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarim_hayvancilik_app/services/analysis_credits.dart';
import 'package:tarim_hayvancilik_app/services/ad_service.dart';

class FakeRewarded implements RewardedGateway {
  int calls = 0;
  int callbacks = 1;
  bool fail = false;
  Completer<void>? wait;
  @override
  Future<void> show(Future<void> Function() earned) async {
    calls++;
    await wait?.future;
    if (fail) throw StateError('offline');
    for (var i = 0; i < callbacks; i++) {
      await earned();
    }
  }
}

void main() {
  late String? saved;
  late DateTime now;
  late AnalysisCredits credits;
  var failWrite = false;
  setUp(() {
    saved = null;
    now = DateTime.utc(2026, 10, 2, 9);
    failWrite = false;
    credits = AnalysisCredits(
      read: () async => saved,
      write: (value) async {
        if (failWrite) throw StateError('disk unavailable');
        saved = value;
      },
      now: () => now,
    );
  });

  Future<bool> analyze({bool success = true}) =>
      credits.run(() async => success, succeeded: (value) => value);

  test(
    'first visit grants three exactly once, concurrent refresh is safe',
    () async {
      await Future.wait(List.generate(8, (_) => credits.refresh()));
      expect(credits.available, 3);
      expect(jsonDecode(saved!)['balance'], 3);
      final reopened = AnalysisCredits(
        read: () async => saved,
        write: (v) async => saved = v,
        now: () => now,
      );
      await reopened.refresh();
      expect(reopened.available, 3);
    },
  );

  test(
    'Istanbul midnight grants one; missed days and clock rollback grant nothing extra',
    () async {
      now = DateTime.utc(2026, 10, 2, 20, 59);
      await credits.refresh();
      now = now.add(const Duration(minutes: 2));
      await Future.wait([credits.refresh(), credits.refresh()]);
      expect(credits.available, 4);
      now = now.add(const Duration(days: 8));
      await credits.refresh();
      expect(credits.available, 5);
      now = now.subtract(const Duration(days: 9));
      await credits.refresh();
      expect(credits.available, 5);
    },
  );

  test(
    'only successful analysis spends one; rejection and exceptions refund reservations',
    () async {
      await credits.refresh();
      await analyze(success: false);
      await expectLater(
        credits.run<bool>(
          () async => throw StateError('network'),
          succeeded: (v) => v,
        ),
        throwsStateError,
      );
      expect(credits.available, 3);
      await analyze();
      expect(credits.available, 2);
    },
  );

  test(
    'last credit cannot fund two concurrent analyses; zero prevents the API call',
    () async {
      await analyze();
      await analyze();
      final pending = Completer<bool>();
      final first = credits.run(() => pending.future, succeeded: (v) => v);
      await Future<void>.delayed(Duration.zero);
      var called = false;
      await expectLater(
        credits.run(() async {
          called = true;
          return true;
        }, succeeded: (v) => v),
        throwsA(isA<NoAnalysisCredits>()),
      );
      expect(called, isFalse);
      pending.complete(true);
      await first;
      expect(credits.available, 0);
      await credits.refresh();
      expect(credits.available, 0);
    },
  );

  test(
    'corrupt wallet is preserved, never overwritten with a fresh welcome bonus',
    () async {
      saved = 'broken';
      await credits.refresh();
      expect(credits.ready, isFalse);
      expect(saved, 'broken');
      await expectLater(analyze(), throwsFormatException);
    },
  );

  test('failed write never reports a granted or consumed credit', () async {
    await credits.refresh();
    failWrite = true;
    await expectLater(credits.grantReward('one'), throwsStateError);
    await expectLater(analyze(), throwsStateError);
    expect(credits.available, 3);
    expect(jsonDecode(saved!)['balance'], 3);
  });

  test(
    'reward is idempotent across duplicate callback and store reopen',
    () async {
      await Future.wait([
        credits.grantReward('receipt'),
        credits.grantReward('receipt'),
      ]);
      expect(credits.available, 4);
      final reopened = AnalysisCredits(
        read: () async => saved,
        write: (v) async => saved = v,
        now: () => now,
      );
      await reopened.grantReward('receipt');
      expect(reopened.available, 4);
    },
  );

  test(
    'reward flow never launches until explicitly called and grants one for duplicate callbacks',
    () async {
      final gateway = FakeRewarded()..callbacks = 2;
      final rewards = RewardCredits(credits, gateway);
      await credits.refresh();
      expect(gateway.calls, 0);
      await rewards.earn();
      expect(credits.available, 4);
      expect(gateway.calls, 1);
    },
  );

  test(
    'skip, load failure and concurrent button taps do not mint credits',
    () async {
      final gateway = FakeRewarded()..callbacks = 0;
      final rewards = RewardCredits(credits, gateway);
      await credits.refresh();
      await rewards.earn();
      expect(credits.available, 3);
      gateway.fail = true;
      await rewards.earn();
      expect(credits.available, 3);
      gateway.fail = false;
      gateway.callbacks = 1;
      gateway.wait = Completer<void>();
      final first = rewards.earn();
      await rewards.earn();
      expect(rewards.busy, isTrue);
      gateway.wait!.complete();
      await first;
      expect(gateway.calls, 3);
      expect(credits.available, 4);
    },
  );

  test('reward save can be retried without watching another ad', () async {
    final gateway = FakeRewarded();
    final rewards = RewardCredits(credits, gateway);
    await credits.refresh();
    failWrite = true;
    await rewards.earn();
    expect(rewards.hasPendingReward, isTrue);
    expect(credits.available, 3);
    failWrite = false;
    await rewards.earn();
    expect(credits.available, 4);
    expect(gateway.calls, 1);
  });
}
