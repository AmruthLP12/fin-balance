import 'package:intl/intl.dart';

/// Centralized currency and number formatting for FinBalance.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrCompactFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  static final NumberFormat _inrWholeFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Format an amount in INR with standard decimals: ₹1,50,000.00
  static String format(double amount, {String symbol = '₹'}) {
    if (symbol == '₹') {
      return _inrFormat.format(amount);
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Format integer paise as currency: formatPaise(1000000) -> ₹10,000.00
  static String formatPaise(int paise, {String symbol = '₹'}) {
    return format(paise / 100.0, symbol: symbol);
  }

  /// Format as whole currency without paise: ₹1,50,000
  static String formatWhole(double amount, {String symbol = '₹'}) {
    if (symbol == '₹') {
      return _inrWholeFormat.format(amount);
    }
    return '$symbol${amount.round()}';
  }

  /// Format compact for large metrics: ₹1.5L, ₹2.4Cr
  static String formatCompact(double amount) {
    return _inrCompactFormat.format(amount);
  }

  /// Format with explicit + or - sign for gains/losses: +₹12,450.00
  static String formatSigned(double amount, {String symbol = '₹'}) {
    final prefix = amount > 0 ? '+' : '';
    return '$prefix${format(amount, symbol: symbol)}';
  }

  /// Format percentages with explicit + sign: +14.2%
  static String formatPercent(double percent) {
    final prefix = percent > 0 ? '+' : '';
    return '$prefix${percent.toStringAsFixed(2)}%';
  }
}
