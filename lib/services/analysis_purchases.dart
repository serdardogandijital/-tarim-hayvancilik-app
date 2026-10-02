import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'analysis_credits.dart';

class AnalysisPack {
  const AnalysisPack(this.id, this.credits, this.plannedPrice);
  final String id;
  final int credits;
  final String plannedPrice;
  static const all = [
    AnalysisPack('ciftci_analiz_10', 10, '9,99 TL'),
    AnalysisPack('ciftci_analiz_50', 50, '44,99 TL'),
  ];
  static AnalysisPack? find(String id) {
    for (final pack in all) {
      if (pack.id == id) return pack;
    }
    return null;
  }
}

class CreditProduct {
  const CreditProduct(this.id, this.price);
  final String id;
  final String price;
}

class CreditTransaction {
  const CreditTransaction(this.id, this.productId);
  final String id;
  final String productId;
}

class PurchaseCanceled implements Exception {}

class PurchasePending implements Exception {}

abstract class CreditStore {
  bool get configured;
  Future<void> initialize(String customerId);
  Future<List<CreditProduct>> products();
  Future<CreditTransaction> purchase(String productId);
  Future<List<CreditTransaction>> transactions();
}

/// The backend owns the authenticated customer ID. A public RevenueCat SDK
/// key is not an authentication token or permission to mint analysis credits.
abstract class PurchaseVerification {
  Future<String?> customerId();
  Future<String> verify(CreditTransaction transaction, AnalysisPack pack);
}

class ServerPurchaseVerification implements PurchaseVerification {
  ServerPurchaseVerification({
    http.Client? client,
    String? endpoint,
    Future<String?> Function()? readSession,
  }) : _client = client ?? http.Client(),
       _endpoint =
           endpoint ??
           const String.fromEnvironment('PURCHASE_VERIFICATION_URL'),
       _readSession =
           readSession ?? (() => _storage.read(key: 'purchase_session_v1'));
  final http.Client _client;
  final String _endpoint;
  final Future<String?> Function() _readSession;
  static const _storage = FlutterSecureStorage();

  // Provisioned by the future authenticated account/session flow, not by
  // guessing a user ID on-device. Missing setup keeps checkout unavailable.
  Future<Map<String, dynamic>?> _session() async {
    final uri = Uri.tryParse(_endpoint);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    final raw = await _readSession();
    if (raw == null) return null;
    final session = jsonDecode(raw) as Map<String, dynamic>;
    if (session['customerId'] is! String ||
        (session['customerId'] as String).isEmpty ||
        session['token'] is! String ||
        (session['token'] as String).isEmpty) {
      return null;
    }
    return session;
  }

  @override
  Future<String?> customerId() async {
    final session = await _session();
    if (session == null) return null;
    final response = await _client
        .get(
          Uri.parse(_endpoint),
          headers: {'Authorization': 'Bearer ${session['token']}'},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['canPurchase'] == true &&
            data['customerId'] == session['customerId']
        ? session['customerId'] as String
        : null;
  }

  @override
  Future<String> verify(
    CreditTransaction transaction,
    AnalysisPack pack,
  ) async {
    final session = await _session();
    if (session == null) {
      throw StateError('Satın alma doğrulaması hazır değil.');
    }
    final response = await _client
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer ${session['token']}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'transactionId': transaction.id,
            'productId': transaction.productId,
            'store': Platform.isIOS ? 'app_store' : 'play_store',
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError('Ödeme doğrulaması tamamlanamadı.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['verified'] != true ||
        data['customerId'] != session['customerId'] ||
        data['transactionId'] != transaction.id ||
        data['productId'] != pack.id ||
        data['credits'] != pack.credits ||
        data['grantId'] is! String ||
        (data['grantId'] as String).isEmpty) {
      throw StateError('Ödeme henüz doğrulanmadı.');
    }
    return data['grantId'] as String;
  }
}

class RevenueCatCreditStore implements CreditStore {
  final Map<String, StoreProduct> _products = {};
  String? _customerId;
  String get _key => kIsWeb
      ? ''
      : Platform.isIOS
      ? const String.fromEnvironment('REVENUECAT_IOS_PUBLIC_KEY')
      : Platform.isAndroid
      ? const String.fromEnvironment('REVENUECAT_ANDROID_PUBLIC_KEY')
      : '';
  @override
  bool get configured =>
      const bool.fromEnvironment('ANALYSIS_PURCHASES_ENABLED') &&
      _key.isNotEmpty;
  @override
  Future<void> initialize(String customerId) async {
    if (_customerId == customerId) return;
    if (_customerId != null) {
      throw StateError('Hesap değişikliği için oturum yeniden açılmalı.');
    }
    if (!configured) throw StateError('Mağaza henüz hazır değil.');
    final config = PurchasesConfiguration(_key)
      ..appUserID = customerId
      ..automaticDeviceIdentifierCollectionEnabled = false;
    await Purchases.configure(config);
    _customerId = customerId;
  }

  @override
  Future<List<CreditProduct>> products() async {
    final products = await Purchases.getProducts(
      AnalysisPack.all.map((p) => p.id).toList(),
      productCategory: ProductCategory.nonSubscription,
    );
    _products.clear();
    for (final product in products) {
      if (AnalysisPack.find(product.identifier) != null) {
        _products[product.identifier] = product;
      }
    }
    return _products.values
        .map((p) => CreditProduct(p.identifier, p.priceString))
        .toList();
  }

  @override
  Future<CreditTransaction> purchase(String productId) async {
    final product = _products[productId];
    if (product == null) throw StateError('Paket mağazada bulunamadı.');
    try {
      final result = await Purchases.purchase(
        PurchaseParams.storeProduct(product),
      );
      final t = result.storeTransaction;
      return CreditTransaction(t.transactionIdentifier, t.productIdentifier);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw PurchaseCanceled();
      }
      if (code == PurchasesErrorCode.paymentPendingError) {
        throw PurchasePending();
      }
      rethrow;
    }
  }

  @override
  Future<List<CreditTransaction>> transactions() async {
    await Purchases.invalidateCustomerInfoCache();
    final info = await Purchases.getCustomerInfo();
    return info.nonSubscriptionTransactions
        .map(
          (t) =>
              CreditTransaction(t.transactionIdentifier, t.productIdentifier),
        )
        .toList();
  }
}

class AnalysisPurchases extends ChangeNotifier {
  AnalysisPurchases({
    required this.store,
    required this.verification,
    required this.credits,
  });
  static final instance = AnalysisPurchases(
    store: RevenueCatCreditStore(),
    verification: ServerPurchaseVerification(),
    credits: AnalysisCredits.instance,
  );
  final CreditStore store;
  final PurchaseVerification verification;
  final AnalysisCredits credits;
  final Map<String, CreditProduct> products = {};
  bool busy = false;
  bool ready = false;
  bool needsSync = false;
  String? _customerId;
  String? message;
  bool canBuy(String productId) =>
      ready && !busy && !needsSync && products.containsKey(productId);

  Future<void> load() async {
    if (busy) return;
    busy = true;
    ready = false;
    message = null;
    notifyListeners();
    try {
      final id = store.configured ? await verification.customerId() : null;
      if (id == null) {
        message =
            'Paketler henüz satışa açılmadı. Ücretsiz haklarını kullanmaya devam edebilirsin.';
        return;
      }
      await store.initialize(id);
      _customerId = id;
      products.clear();
      for (final p in await store.products()) {
        if (AnalysisPack.find(p.id) != null) products[p.id] = p;
      }
      // Recover verified purchases after an interrupted grant before permitting
      // another checkout. Replay is harmless because grants are durable/idempotent.
      needsSync = true;
      await _sync();
      ready = true;
      if (products.isEmpty) {
        message =
            'Paketler şu anda mağazada bulunamıyor. Daha sonra tekrar dene.';
      }
    } catch (_) {
      message = 'Mağazaya bağlanılamadı. Bağlantını kontrol edip tekrar dene.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> _deliver(CreditTransaction transaction) async {
    final pack = AnalysisPack.find(transaction.productId);
    if (pack == null) return false;
    if (transaction.id.isEmpty) throw StateError('İşlem kimliği eksik.');
    final receipt = '${transaction.productId}:${transaction.id}';
    if (await credits.hasPurchase(receipt)) return false;
    final grant = await verification.verify(transaction, pack);
    await credits.grantPurchase(
      receipt: receipt,
      grantId: grant,
      amount: pack.credits,
      productId: pack.id,
    );
    return true;
  }

  Future<void> _sync() async {
    for (final transaction in await store.transactions()) {
      await _deliver(transaction);
    }
    needsSync = await credits.pendingPurchase() != null;
  }

  Future<void> buy(String productId) async {
    if (!canBuy(productId)) return;
    busy = true;
    message = null;
    notifyListeners();
    try {
      // Recheck authentication/service readiness immediately before charging.
      if (await verification.customerId() != _customerId ||
          _customerId == null) {
        ready = false;
        message = 'Bağlantı doğrulanamadı. Ödeme başlatılmadı.';
        return;
      }
      await credits.setPendingPurchase(productId);
      final transaction = await store.purchase(productId);
      needsSync = true;
      if (transaction.productId != productId) {
        throw StateError('Paket eşleşmedi.');
      }
      final delivered = await _deliver(transaction);
      needsSync = await credits.pendingPurchase() != null;
      if (!delivered) {
        message = 'Bu işlem daha önce işlendi. Yeni ödeme varsa onayını bekle.';
        return;
      }
      message =
          '${AnalysisPack.find(productId)!.credits} analiz hakkı eklendi.';
    } on PurchaseCanceled {
      try {
        await credits.setPendingPurchase(null);
        needsSync = false;
      } catch (_) {
        needsSync = true;
      }
      message = 'Satın alma iptal edildi. Hakların değişmedi.';
    } on PurchasePending {
      needsSync = true;
      message =
          'Ödeme onay bekliyor. Onaylandıktan sonra ödemeyi kontrol edebilirsin.';
    } catch (_) {
      needsSync = true;
      message =
          'İşlem tamamlanamadı. Yeniden satın almadan önce ödemeyi kontrol et.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> sync() async {
    if (busy || !ready) {
      if (!busy) await load();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      await _sync();
      message = needsSync
          ? 'Ödeme henüz onaylanmadı. Yeni ödeme başlatmadan daha sonra tekrar kontrol et.'
          : 'Onaylanan ödemeler kontrol edildi. Yeni bir ödeme alınmadı.';
    } catch (_) {
      needsSync = true;
      message =
          'Ödeme kontrol edilemedi. Daha sonra tekrar dene; yeniden satın alma yapmana gerek yok.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
