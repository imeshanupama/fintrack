import 'package:hive/hive.dart';

part 'exchange_rate.g.dart';

@HiveType(typeId: 12)
class ExchangeRate extends HiveObject {
  @HiveField(0)
  final String baseCurrency;

  @HiveField(1)
  final String targetCurrency;

  @HiveField(2)
  final double rate;

  @HiveField(3)
  final DateTime lastUpdated;

  ExchangeRate({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.rate,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Convert amount from base to target currency
  double convert(double amount) => amount * rate;

  // Check if rate is stale (older than 24 hours)
  bool isStale() {
    final now = DateTime.now();
    return now.difference(lastUpdated).inHours > 24;
  }

  // Get unique key for this currency pair
  String get key => '${baseCurrency}_$targetCurrency';

  ExchangeRate copyWith({
    String? baseCurrency,
    String? targetCurrency,
    double? rate,
    DateTime? lastUpdated,
  }) {
    return ExchangeRate(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      rate: rate ?? this.rate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseCurrency': baseCurrency,
      'targetCurrency': targetCurrency,
      'rate': rate,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      baseCurrency: json['baseCurrency'] as String,
      targetCurrency: json['targetCurrency'] as String,
      rate: (json['rate'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}
