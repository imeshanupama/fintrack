import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../domain/exchange_rate.dart';
import '../data/exchange_rate_repository.dart';
import '../application/exchange_rate_service.dart';
import '../application/currency_converter.dart';
import '../../settings/data/settings_repository.dart';

// Services
final exchangeRateServiceProvider = Provider((ref) => ExchangeRateService());

// Base currency notifier with persistent storage
class BaseCurrencyNotifier extends Notifier<String> {
  @override
  String build() {
    // Load saved currency from settings, default to USD
    final settingsRepo = ref.read(settingsRepositoryProvider);
    return settingsRepo.getCurrency();
  }

  void setCurrency(String currency) async {
    // Save to settings for persistence
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.setCurrency(currency);
    
    // Update state
    state = currency;
    
    // Automatically fetch rates for new currency
    try {
      final service = ref.read(exchangeRateServiceProvider);
      final repository = ref.read(exchangeRateRepositoryProvider);
      final rates = await service.fetchRates(currency);
      await repository.saveRates(rates);
      
      // Invalidate to trigger UI refresh
      ref.invalidate(exchangeRatesProvider);
    } catch (e) {
      // Silently fail, will use cached rates
    }
  }
}

final baseCurrencyProvider = NotifierProvider<BaseCurrencyNotifier, String>(BaseCurrencyNotifier.new);

// Exchange rates provider
final exchangeRatesProvider = FutureProvider<Map<String, ExchangeRate>>((ref) async {
  final repository = ref.watch(exchangeRateRepositoryProvider);
  final baseCurrency = ref.watch(baseCurrencyProvider);
  
  // Try to get from cache first
  final cachedRates = repository.getRatesForBase(baseCurrency);
  
  // If cache is empty or stale, fetch new rates
  if (cachedRates.isEmpty || cachedRates.values.any((rate) => rate.isStale())) {
    try {
      final service = ref.read(exchangeRateServiceProvider);
      final freshRates = await service.fetchRates(baseCurrency);
      await repository.saveRates(freshRates);
      return freshRates;
    } catch (e) {
      // If fetch fails, return cached rates (offline fallback)
      if (cachedRates.isNotEmpty) {
        return cachedRates;
      }
      rethrow;
    }
  }
  
  return cachedRates;
});

// Currency converter provider
final currencyConverterProvider = Provider<CurrencyConverter?>((ref) {
  final ratesAsync = ref.watch(exchangeRatesProvider);
  
  return ratesAsync.when(
    data: (rates) => CurrencyConverter(rates),
    loading: () => null,
    error: (_, __) => null,
  );
});

// Notifier for currency operations
class CurrencyNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  // Update exchange rates manually
  Future<void> updateRates() async {
    state = const AsyncValue.loading();
    
    try {
      final service = ref.read(exchangeRateServiceProvider);
      final repository = ref.read(exchangeRateRepositoryProvider);
      final baseCurrency = ref.read(baseCurrencyProvider);
      
      final rates = await service.fetchRates(baseCurrency);
      await repository.saveRates(rates);
      
      // Invalidate the provider to trigger refresh
      ref.invalidate(exchangeRatesProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Set base currency
  Future<void> setBaseCurrency(String currency) async {
    // Update the base currency
    ref.read(baseCurrencyProvider.notifier).setCurrency(currency);
    
    // Fetch rates for new base currency
    await updateRates();
  }

  // Convert amount
  double convertAmount(double amount, String from, String to) {
    final converter = ref.read(currencyConverterProvider);
    if (converter == null) return amount;
    
    return converter.convert(amount: amount, from: from, to: to);
  }

  // Get formatted amount
  String formatAmount(double amount, String currencyCode) {
    final converter = ref.read(currencyConverterProvider);
    if (converter == null) return '$currencyCode $amount';
    
    return converter.formatAmount(amount, currencyCode);
  }
}

final currencyNotifierProvider = NotifierProvider<CurrencyNotifier, AsyncValue<void>>(CurrencyNotifier.new);
