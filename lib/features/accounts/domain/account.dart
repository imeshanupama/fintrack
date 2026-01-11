import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 0)
class Account extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double balance;

  @HiveField(3)
  final String currencyCode;

  @HiveField(4)
  final int colorValue; // Storing color as int

  @HiveField(5)
  final int iconCode; // Storing icon data (e.g. font awesome code point)

  Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.currencyCode,
    required this.colorValue,
    required this.iconCode,
  });

  Account copyWith({
    String? id,
    String? name,
    double? balance,
    String? currencyCode,
    int? colorValue,
    int? iconCode,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currencyCode: currencyCode ?? this.currencyCode,
      colorValue: colorValue ?? this.colorValue,
      iconCode: iconCode ?? this.iconCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'currencyCode': currencyCode,
      'colorValue': colorValue,
      'iconCode': iconCode,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      colorValue: json['colorValue'] as int,
      iconCode: json['iconCode'] as int,
    );
  }
}
