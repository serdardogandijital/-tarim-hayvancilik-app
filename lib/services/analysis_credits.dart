import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NoAnalysisCredits implements Exception {
  @override
  String toString() =>
      'Analiz hakkınız bitti. Sonraki gün giriş yaptığınızda +1 bonus hak kazanırsınız.';
}

/// Guest-device wallet. This is NOT a server-authoritative account or clock.
/// A future account backend must enforce grants and verify rewarded ads there.
class AnalysisCredits extends ChangeNotifier {
  static final instance = AnalysisCredits();
  static const storageKey = 'analysis_credits_v1';
  static const _storage = FlutterSecureStorage();

  AnalysisCredits({
    Future<String?> Function()? read,
    Future<void> Function(String)? write,
    DateTime Function()? now,
  }) : _read = read ?? (() => _storage.read(key: storageKey)),
       _write =
           write ?? ((value) => _storage.write(key: storageKey, value: value)),
       _now = now ?? DateTime.now;

  final Future<String?> Function() _read;
  final Future<void> Function(String) _write;
  final DateTime Function() _now;
  Future<void> _queue = Future.value();
  int _balance = 0;
  int _reserved = 0;
  bool ready = false;
  String? error;
  int get available => (_balance - _reserved).clamp(0, _balance);

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  String get _today => _now()
      .toUtc()
      .add(const Duration(hours: 3))
      .toIso8601String()
      .substring(0, 10);

  Future<Map<String, dynamic>> _load() async {
    final raw = await _read();
    if (raw == null) {
      final created = <String, dynamic>{
        'version': 1,
        'balance': 3,
        'day': _today,
        'rewards': <String>[],
      };
      await _write(jsonEncode(created));
      return created;
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['version'] != 1 ||
        data['balance'] is! int ||
        (data['balance'] as int) < 0 ||
        data['day'] is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(data['day']) ||
        data['rewards'] is! List ||
        (data['rewards'] as List).any((id) => id is! String)) {
      throw const FormatException('Hak kaydı okunamadı');
    }
    final purchases = data['purchases'];
    if (purchases != null &&
        (purchases is! Map ||
            purchases.values.any(
              (p) =>
                  p is! Map ||
                  p['grantId'] is! String ||
                  (p['grantId'] as String).isEmpty ||
                  ![10, 50].contains(p['amount']),
            ))) {
      throw const FormatException('Ödeme kayıtları okunamadı');
    }
    // One grant for a visited day, never backfill missed days or grant on rollback.
    if (_today.compareTo(data['day'] as String) > 0) {
      data['balance'] = (data['balance'] as int) + 1;
      data['day'] = _today;
      await _write(jsonEncode(data));
    }
    return data;
  }

  void _publish(Map<String, dynamic> data) {
    _balance = data['balance'] as int;
    ready = true;
    error = null;
    notifyListeners();
  }

  Future<void> refresh() => _serial(() async {
    try {
      _publish(await _load());
    } catch (_) {
      ready = false;
      error =
          'Haklar okunamadı. Tekrar deneyin; mevcut kayıtlarınız korunuyor.';
      notifyListeners();
    }
  });

  Future<T> run<T>(
    Future<T> Function() analyze, {
    required bool Function(T) succeeded,
  }) async {
    await _serial(() async {
      final data = await _load();
      _publish(data);
      if (available < 1) throw NoAnalysisCredits();
      _reserved++;
      notifyListeners();
    });
    // Reservations are in memory: a crash before a successful result cannot
    // destroy a credit. Concurrent requests cannot spend the same available unit.
    try {
      final result = await analyze();
      if (succeeded(result)) {
        await _serial(() async {
          final data = await _load();
          data['balance'] = (data['balance'] as int) - 1;
          await _write(jsonEncode(data));
          _publish(data);
        });
      }
      return result;
    } finally {
      await _serial(() async {
        _reserved--;
        notifyListeners();
      });
    }
  }

  Future<String?> pendingPurchase() => _serial(() async {
    final data = await _load();
    final pending = data['pendingPurchase'];
    if (pending != null && pending is! String) {
      throw const FormatException('Bekleyen ödeme okunamadı');
    }
    return pending as String?;
  });

  Future<void> setPendingPurchase(String? productId) => _serial(() async {
    final data = await _load();
    if (productId == null) {
      data.remove('pendingPurchase');
    } else {
      data['pendingPurchase'] = productId;
    }
    await _write(jsonEncode(data));
    _publish(data);
  });

  Future<bool> hasPurchase(String receipt) => _serial(() async {
    final data = await _load();
    final purchases = data['purchases'] ?? <String, dynamic>{};
    if (purchases is! Map) throw const FormatException('Ödeme kaydı okunamadı');
    return purchases.containsKey(receipt);
  });

  /// Called only with a server-verified grant; persists credit and receipt in
  /// one secure-storage write. Do not mint credits directly from SDK callbacks.
  Future<void> grantPurchase({
    required String receipt,
    required String grantId,
    required int amount,
    String? productId,
  }) => _serial(() async {
    if (receipt.isEmpty || grantId.isEmpty || ![10, 50].contains(amount)) {
      throw ArgumentError('Geçersiz analiz paketi');
    }
    final data = await _load();
    final purchases = Map<String, dynamic>.from(
      data['purchases'] as Map? ?? {},
    );
    final existing = purchases[receipt];
    if (existing != null) {
      if (existing is! Map ||
          existing['amount'] != amount ||
          existing['grantId'] != grantId) {
        throw const FormatException('Ödeme kaydı eşleşmedi');
      }
    } else {
      if (purchases.values.any((p) => p is Map && p['grantId'] == grantId)) {
        throw const FormatException('Ödeme daha önce işlendi');
      }
      purchases[receipt] = {'grantId': grantId, 'amount': amount};
      data['purchases'] = purchases;
      if (productId != null && data['pendingPurchase'] == productId) {
        data.remove('pendingPurchase');
      }
      data['balance'] = (data['balance'] as int) + amount;
      await _write(jsonEncode(data));
    }
    _publish(data);
  });

  /// A receipt is granted once even if the SDK repeats the reward callback.
  Future<void> grantReward(String receipt) => _serial(() async {
    final data = await _load();
    final rewards = List<String>.from(data['rewards'] as List);
    if (!rewards.contains(receipt)) {
      rewards.add(receipt);
      data['rewards'] = rewards;
      data['balance'] = (data['balance'] as int) + 1;
      await _write(jsonEncode(data));
    }
    _publish(data);
  });
}
