import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageFailure implements Exception {
  const StorageFailure();
  @override
  String toString() =>
      'Kayıtlar okunamadı veya kaydedilemedi. Mevcut veriler korunuyor.';
}

class RecordValidationFailure implements Exception {
  const RecordValidationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Keeps legacy keys/schema, serializes read-modify-write, and never overwrites
/// unreadable data. A previous valid snapshot is retained for recovery.
class SafeListStore<T> {
  SafeListStore(this.key, this.decode, this.encode);
  final String key;
  final T Function(Map<String, dynamic>) decode;
  final Map<String, dynamic> Function(T) encode;
  Future<void>? _pending;
  static final errors = ValueNotifier<Set<String>>({});
  static final revision = ValueNotifier<int>(0);

  Future<R> _serial<R>(Future<R> Function() action) {
    final previous = _pending;
    final gate = Completer<void>();
    _pending = gate.future;
    Future<R> invoke() async {
      try {
        if (previous != null) await previous;
        return await action();
      } finally {
        if (identical(_pending, gate.future)) _pending = null;
        gate.complete();
      }
    }

    return invoke();
  }

  List<T> _read(SharedPreferences prefs) {
    final raw = prefs.getString(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((item) => decode(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  void _failed() => errors.value = {...errors.value, key};

  Future<List<T>> load() => _serial(() async {
    try {
      final records = _read(await SharedPreferences.getInstance());
      errors.value = {...errors.value}..remove(key);
      return records;
    } catch (_) {
      _failed();
      return <T>[];
    }
  });

  Future<void> change(void Function(List<T>) update) => _serial(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = _read(prefs); // Intentionally strict on every write.
      update(records);
      final next = jsonEncode(records.map(encode).toList());
      final previous = prefs.getString(key);
      if (previous != null &&
          !await prefs.setString('${key}_backup', previous)) {
        throw const StorageFailure();
      }
      if (!await prefs.setString(key, next)) throw const StorageFailure();
      errors.value = {...errors.value}..remove(key);
      revision.value++;
    } on RecordValidationFailure {
      rethrow;
    } catch (_) {
      _failed();
      throw const StorageFailure();
    }
  });

  Future<void> replace(List<T> records) => change((current) {
    current
      ..clear()
      ..addAll(records);
  });
}
