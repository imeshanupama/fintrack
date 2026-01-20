class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final String flag;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });
}

// Popular currencies with their metadata
const Map<String, CurrencyInfo> currencies = {
  'USD': CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
  'EUR': CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
  'GBP': CurrencyInfo(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧'),
  'JPY': CurrencyInfo(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵'),
  'INR': CurrencyInfo(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
  'LKR': CurrencyInfo(code: 'LKR', name: 'Sri Lankan Rupee', symbol: 'Rs', flag: '🇱🇰'),
  'AUD': CurrencyInfo(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', flag: '🇦🇺'),
  'CAD': CurrencyInfo(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', flag: '🇨🇦'),
  'CHF': CurrencyInfo(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr', flag: '🇨🇭'),
  'CNY': CurrencyInfo(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳'),
  'SEK': CurrencyInfo(code: 'SEK', name: 'Swedish Krona', symbol: 'kr', flag: '🇸🇪'),
  'NZD': CurrencyInfo(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$', flag: '🇳🇿'),
  'MXN': CurrencyInfo(code: 'MXN', name: 'Mexican Peso', symbol: '\$', flag: '🇲🇽'),
  'SGD': CurrencyInfo(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', flag: '🇸🇬'),
  'HKD': CurrencyInfo(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$', flag: '🇭🇰'),
  'NOK': CurrencyInfo(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr', flag: '🇳🇴'),
  'KRW': CurrencyInfo(code: 'KRW', name: 'South Korean Won', symbol: '₩', flag: '🇰🇷'),
  'TRY': CurrencyInfo(code: 'TRY', name: 'Turkish Lira', symbol: '₺', flag: '🇹🇷'),
  'RUB': CurrencyInfo(code: 'RUB', name: 'Russian Ruble', symbol: '₽', flag: '🇷🇺'),
  'BRL': CurrencyInfo(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', flag: '🇧🇷'),
  'ZAR': CurrencyInfo(code: 'ZAR', name: 'South African Rand', symbol: 'R', flag: '🇿🇦'),
  'AED': CurrencyInfo(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪'),
  'SAR': CurrencyInfo(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼', flag: '🇸🇦'),
  'THB': CurrencyInfo(code: 'THB', name: 'Thai Baht', symbol: '฿', flag: '🇹🇭'),
  'IDR': CurrencyInfo(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp', flag: '🇮🇩'),
  'MYR': CurrencyInfo(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM', flag: '🇲🇾'),
  'PHP': CurrencyInfo(code: 'PHP', name: 'Philippine Peso', symbol: '₱', flag: '🇵🇭'),
  'PKR': CurrencyInfo(code: 'PKR', name: 'Pakistani Rupee', symbol: '₨', flag: '🇵🇰'),
  'BDT': CurrencyInfo(code: 'BDT', name: 'Bangladeshi Taka', symbol: '৳', flag: '🇧🇩'),
  'VND': CurrencyInfo(code: 'VND', name: 'Vietnamese Dong', symbol: '₫', flag: '🇻🇳'),
};

// Popular currencies list for quick access
const List<String> popularCurrencies = [
  'USD', 'EUR', 'GBP', 'JPY', 'INR', 'LKR',
  'AUD', 'CAD', 'CHF', 'CNY',
];

// Get currency symbol
String getCurrencySymbol(String currencyCode) {
  return currencies[currencyCode]?.symbol ?? currencyCode;
}

// Get currency flag
String getCurrencyFlag(String currencyCode) {
  return currencies[currencyCode]?.flag ?? '🌍';
}

// Get currency name
String getCurrencyName(String currencyCode) {
  return currencies[currencyCode]?.name ?? currencyCode;
}
