import '../domain/exchange_rate.dart';
import '../domain/currency_constants.dart';
import '../../accounts/domain/account.dart';
import '../../transactions/domain/transaction.dart';

class CurrencyConverter {
  final Map<String, ExchangeRate> rates;

  CurrencyConverter(this.rates);

  /// Convert amount from one currency to another
  double convert({
    required double amount,
    required String from,
    required String to,
  }) {
    // Same currency, no conversion needed
    if (from == to) return amount;

    // Direct conversion available
    final directKey = '${from}_$to';
    if (rates.containsKey(directKey)) {
      return rates[directKey]!.convert(amount);
    }

    // Try inverse rate (e.g., if we have LKR_USD but need USD_LKR)
    final inverseKey = '${to}_$from';
    if (rates.containsKey(inverseKey)) {
      final inverseRate = rates[inverseKey]!.rate;
      if (inverseRate != 0) {
        return amount / inverseRate; // Inverse conversion
      }
    }

    // Cross conversion via USD
    final fromToUsd = '${from}_USD';
    final usdToTarget = 'USD_$to';

    if (rates.containsKey(fromToUsd) && rates.containsKey(usdToTarget)) {
      final usdAmount = rates[fromToUsd]!.convert(amount);
      return rates[usdToTarget]!.convert(usdAmount);
    }

    // Fallback: return original amount if no rate available
    return amount;
  }

  /// Convert account balance to target currency
  double convertAccount(Account account, String targetCurrency) {
    return convert(
      amount: account.balance,
      from: account.currencyCode,
      to: targetCurrency,
    );
  }

  /// Convert transaction amount to target currency
  double convertTransaction(Transaction transaction, String targetCurrency) {
    return convert(
      amount: transaction.amount,
      from: transaction.currencyCode,
      to: targetCurrency,
    );
  }

  /// Get total of all accounts in target currency
  double getTotalInCurrency(List<Account> accounts, String targetCurrency) {
    return accounts.fold(0.0, (sum, account) {
      return sum + convertAccount(account, targetCurrency);
    });
  }

  /// Format amount with currency symbol
  String formatAmount(double amount, String currencyCode) {
    final symbol = getCurrencySymbol(currencyCode);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Get exchange rate between two currencies
  double? getRate(String from, String to) {
    if (from == to) return 1.0;

    final key = '${from}_$to';
    return rates[key]?.rate;
  }

  /// Check if conversion is available
  bool canConvert(String from, String to) {
    if (from == to) return true;
    return getRate(from, to) != null;
  }
}
