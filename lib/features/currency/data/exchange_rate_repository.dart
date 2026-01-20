import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/box_names.dart';
import '../domain/exchange_rate.dart';

final exchangeRateRepositoryProvider = Provider((ref) => ExchangeRateRepository());

class ExchangeRateRepository {
  Box<ExchangeRate> get _box => Hive.box<ExchangeRate>(BoxNames.exchangeRatesBox);

  // Create/Update
  Future<void> saveRate(ExchangeRate rate) async {
    await _box.put(rate.key, rate);
  }

  Future<void> saveRates(Map<String, ExchangeRate> rates) async {
    for (final rate in rates.values) {
      await _box.put(rate.key, rate);
    }
  }

  // Read
  ExchangeRate? getRate(String baseCurrency, String targetCurrency) {
    final key = '${baseCurrency}_$targetCurrency';
    return _box.get(key);
  }

  Map<String, ExchangeRate> getAllRates() {
    return Map.fromEntries(
      _box.values.map((rate) => MapEntry(rate.key, rate)),
    );
  }

  Map<String, ExchangeRate> getRatesForBase(String baseCurrency) {
    return Map.fromEntries(
      _box.values
          .where((rate) => rate.baseCurrency == baseCurrency)
          .map((rate) => MapEntry(rate.key, rate)),
    );
  }

  List<ExchangeRate> getStaleRates() {
    return _box.values.where((rate) => rate.isStale()).toList();
  }

  // Delete
  Future<void> deleteRate(String baseCurrency, String targetCurrency) async {
    final key = '${baseCurrency}_$targetCurrency';
    await _box.delete(key);
  }

  Future<void> clearOldRates({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final oldRates = _box.values
        .where((rate) => rate.lastUpdated.isBefore(cutoffDate))
        .toList();

    for (final rate in oldRates) {
      await _box.delete(rate.key);
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  // Stream for real-time updates
  Stream<Map<String, ExchangeRate>> watchRates() {
    return _box.watch().map((_) => getAllRates());
  }

  Stream<Map<String, ExchangeRate>> watchRatesForBase(String baseCurrency) {
    return _box.watch().map((_) => getRatesForBase(baseCurrency));
  }
}
