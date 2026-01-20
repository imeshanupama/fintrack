import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/exchange_rate.dart';

class ExchangeRateService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';

  /// Fetch latest exchange rates for a base currency
  Future<Map<String, ExchangeRate>> fetchRates(String baseCurrency) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$baseCurrency'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        final timestamp = DateTime.now();

        final exchangeRates = <String, ExchangeRate>{};

        for (final entry in rates.entries) {
          final targetCurrency = entry.key;
          final rate = (entry.value as num).toDouble();

          final exchangeRate = ExchangeRate(
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rate: rate,
            lastUpdated: timestamp,
          );

          exchangeRates[exchangeRate.key] = exchangeRate;
        }

        return exchangeRates;
      } else {
        throw Exception('Failed to fetch exchange rates: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching exchange rates: $e');
    }
  }

  /// Fetch rate for a specific currency pair
  Future<ExchangeRate?> fetchRate(String baseCurrency, String targetCurrency) async {
    try {
      final rates = await fetchRates(baseCurrency);
      return rates['${baseCurrency}_$targetCurrency'];
    } catch (e) {
      return null;
    }
  }

  /// Check if API is available
  Future<bool> checkApiAvailability() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/USD'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
