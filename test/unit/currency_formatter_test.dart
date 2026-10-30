import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/core/formatting/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats standard INR amounts with decimals', () {
      final formatted = CurrencyFormatter.format(150000.50);
      expect(formatted, contains('1,50,000.50'));
      expect(formatted, contains('₹'));
    });

    test('formats whole amounts without paise', () {
      final formatted = CurrencyFormatter.formatWhole(5000.0);
      expect(formatted, contains('5,000'));
      expect(formatted, contains('₹'));
    });

    test('formats signed gains with positive prefix', () {
      final formatted = CurrencyFormatter.formatSigned(2500.0);
      expect(formatted, startsWith('+'));
      expect(formatted, contains('2,500'));
    });

    test('formats signed losses with negative prefix', () {
      final formatted = CurrencyFormatter.formatSigned(-1200.0);
      expect(formatted, contains('-'));
      expect(formatted, contains('1,200'));
    });

    test('formats positive percentage', () {
      final formatted = CurrencyFormatter.formatPercent(12.456);
      expect(formatted, equals('+12.46%'));
    });

    test('formats negative percentage', () {
      final formatted = CurrencyFormatter.formatPercent(-4.2);
      expect(formatted, equals('-4.20%'));
    });
  });
}
