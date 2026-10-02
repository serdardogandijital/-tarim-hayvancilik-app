import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarim_hayvancilik_app/services/analysis_credits.dart';
import 'package:tarim_hayvancilik_app/services/analysis_purchases.dart';

class FakeStore implements CreditStore {
  @override
  bool configured = true;
  int purchases = 0;
  Object? failure;
  Completer<void>? gate;
  final history = <CreditTransaction>[];
  @override
  Future<void> initialize(String customerId) async {}
  @override
  Future<List<CreditProduct>> products() async => [
    const CreditProduct('ciftci_analiz_10', '₺9,99'),
    const CreditProduct('ciftci_analiz_50', '₺44,99'),
  ];
  @override
  Future<CreditTransaction> purchase(String id) async {
    purchases++;
    if (gate != null) await gate!.future;
    if (failure != null) throw failure!;
    final t = CreditTransaction('tx-$purchases', id);
    history.add(t);
    return t;
  }

  @override
  Future<List<CreditTransaction>> transactions() async => List.of(history);
}

class FakeVerification implements PurchaseVerification {
  bool valid = true;
  String? account = 'customer';
  @override
  Future<String?> customerId() async => account;
  @override
  Future<String> verify(CreditTransaction t, AnalysisPack p) async {
    if (!valid) throw StateError('unverified');
    return 'grant-${t.id}';
  }
}

void main() {
  late String? saved;
  late bool failGrantWrite;
  late AnalysisCredits credits;
  late FakeStore store;
  late FakeVerification verification;
  late AnalysisPurchases purchases;
  setUp(() async {
    saved = null;
    failGrantWrite = false;
    credits = AnalysisCredits(
      read: () async => saved,
      write: (v) async {
        if (failGrantWrite && v.contains('"purchases"'))
          throw StateError('disk');
        saved = v;
      },
    );
    store = FakeStore();
    verification = FakeVerification();
    purchases = AnalysisPurchases(
      store: store,
      verification: verification,
      credits: credits,
    );
    await credits.refresh();
    await purchases.load();
  });
  test('verified 10 and 50 packs add once; prices come from store', () async {
    expect(purchases.products['ciftci_analiz_10']!.price, '₺9,99');
    await purchases.buy('ciftci_analiz_10');
    expect(credits.available, 13);
    await purchases.buy('ciftci_analiz_50');
    expect(credits.available, 63);
    await purchases.sync();
    await purchases.load();
    expect(credits.available, 63);
  });
  test('cancellation never grants and releases checkout', () async {
    store.failure = PurchaseCanceled();
    await purchases.buy('ciftci_analiz_10');
    expect(credits.available, 3);
    expect(purchases.canBuy('ciftci_analiz_10'), isTrue);
    expect(await credits.pendingPurchase(), isNull);
  });
  test(
    'pending payment survives reload without granting or second checkout',
    () async {
      store.failure = PurchasePending();
      await purchases.buy('ciftci_analiz_10');
      await purchases.load();
      await purchases.sync();
      expect(purchases.needsSync, isTrue);
      await purchases.buy('ciftci_analiz_10');
      expect(store.purchases, 1);
      expect(credits.available, 3);
      store.history.add(
        const CreditTransaction('pending-approved', 'ciftci_analiz_10'),
      );
      await purchases.sync();
      expect(credits.available, 13);
      expect(purchases.needsSync, isFalse);
    },
  );
  test(
    'verification outage does not grant; recovery never bills again',
    () async {
      verification.valid = false;
      await purchases.buy('ciftci_analiz_10');
      expect(credits.available, 3);
      expect(purchases.needsSync, isTrue);
      await purchases.buy('ciftci_analiz_10');
      expect(store.purchases, 1);
      verification.valid = true;
      await purchases.sync();
      await purchases.sync();
      expect(credits.available, 13);
      expect(store.purchases, 1);
    },
  );
  test(
    'durable grant failure is recoverable without losing receipt or duplicating credits',
    () async {
      failGrantWrite = true;
      await purchases.buy('ciftci_analiz_50');
      expect(credits.available, 3);
      failGrantWrite = false;
      final reopened = AnalysisCredits(
        read: () async => saved,
        write: (v) async => saved = v,
      );
      await reopened.refresh();
      final resumed = AnalysisPurchases(
        store: store,
        verification: verification,
        credits: reopened,
      );
      await resumed.load();
      await resumed.sync();
      expect(reopened.available, 53);
      expect(store.purchases, 1);
    },
  );
  test('double tap has one checkout and one grant', () async {
    store.gate = Completer<void>();
    final first = purchases.buy('ciftci_analiz_10');
    await purchases.buy('ciftci_analiz_10');
    store.gate!.complete();
    await first;
    expect(store.purchases, 1);
    expect(credits.available, 13);
  });
  test(
    'unconfigured store or missing account never permits checkout',
    () async {
      store.configured = false;
      await purchases.load();
      await purchases.buy('ciftci_analiz_10');
      expect(store.purchases, 0);
      expect(purchases.ready, isFalse);
      store.configured = true;
      verification.account = null;
      await purchases.load();
      expect(purchases.canBuy('ciftci_analiz_10'), isFalse);
    },
  );
  test('unknown product and malformed transaction do not grant', () async {
    store.history.add(const CreditTransaction('unknown', 'other_app_pack'));
    await purchases.sync();
    expect(credits.available, 3);
    store.history.add(const CreditTransaction('', 'ciftci_analiz_10'));
    await purchases.sync();
    expect(credits.available, 3);
    expect(purchases.needsSync, isTrue);
  });
  test(
    'one verified grant cannot be replayed with a different receipt or quantity',
    () async {
      await credits.grantPurchase(receipt: 'r1', grantId: 'g1', amount: 10);
      await expectLater(
        credits.grantPurchase(receipt: 'r2', grantId: 'g1', amount: 50),
        throwsFormatException,
      );
      await expectLater(
        credits.grantPurchase(receipt: 'r1', grantId: 'g1', amount: 50),
        throwsFormatException,
      );
      expect(credits.available, 13);
    },
  );
  test(
    'verification response must match account, transaction, product and quantity',
    () async {
      final correct = <String, dynamic>{
        'verified': true,
        'customerId': 'customer',
        'transactionId': 't1',
        'productId': 'ciftci_analiz_10',
        'credits': 10,
        'grantId': 'g1',
      };
      var response = Map<String, dynamic>.of(correct);
      final verifier = ServerPurchaseVerification(
        endpoint: 'https://verify.example.test/purchase',
        readSession: () async =>
            jsonEncode({'customerId': 'customer', 'token': 'session'}),
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer session');
          expect(jsonDecode(request.body)['productId'], 'ciftci_analiz_10');
          return http.Response(jsonEncode(response), 200);
        }),
      );
      const transaction = CreditTransaction('t1', 'ciftci_analiz_10');
      for (final override in [
        {'verified': false},
        {'customerId': 'other'},
        {'transactionId': 'other'},
        {'productId': 'ciftci_analiz_50'},
        {'credits': 50},
        {'grantId': ''},
      ]) {
        response = {...correct, ...override};
        await expectLater(
          verifier.verify(transaction, AnalysisPack.all.first),
          throwsStateError,
        );
      }
      response = correct;
      expect(await verifier.verify(transaction, AnalysisPack.all.first), 'g1');
    },
  );
  test(
    'insecure verification URL and missing session keep payment unavailable',
    () async {
      final verifier = ServerPurchaseVerification(
        endpoint: 'http://verify.example.test',
        readSession: () async =>
            jsonEncode({'customerId': 'customer', 'token': 'session'}),
      );
      expect(await verifier.customerId(), isNull);
      final empty = ServerPurchaseVerification(
        endpoint: 'https://verify.example.test',
        readSession: () async => null,
      );
      expect(await empty.customerId(), isNull);
    },
  );
  test('expired session after loading catalog cannot start a charge', () async {
    verification.account = null;
    await purchases.buy('ciftci_analiz_10');
    expect(store.purchases, 0);
    expect(credits.available, 3);
    expect(purchases.ready, isFalse);
  });
}
