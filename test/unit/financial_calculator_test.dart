import 'package:finbalance/core/calculations/financial_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FinancialCalculator Tests', () {
    test(
        'calculateAbsoluteReturn returns exact percentage and handles 0 invested',
        () {
      expect(
        FinancialCalculator.calculateAbsoluteReturn(
          investedPaise: 10000000, // ₹1,00,000
          currentValuationPaise: 12000000, // ₹1,20,000
        ),
        closeTo(20.0, 0.001),
      );

      expect(
        FinancialCalculator.calculateAbsoluteReturn(
          investedPaise: 10000000,
          currentValuationPaise: 8000000, // ₹80,000
        ),
        closeTo(-20.0, 0.001),
      );

      expect(
        FinancialCalculator.calculateAbsoluteReturn(
          investedPaise: 0,
          currentValuationPaise: 5000000,
        ),
        0.0,
      );
    });

    test('calculateProfitLossPaise calculates exact paise difference', () {
      expect(
        FinancialCalculator.calculateProfitLossPaise(
          investedPaise: 5000000,
          currentValuationPaise: 6500000,
        ),
        1500000,
      );
    });

    test('calculateXirr solves standard 1-year lump sum growth', () {
      // Invested ₹10,000 on Jan 1, 2024. Valued at ₹11,200 on Jan 1, 2025 (12% gain in 1 year).
      final cashFlows = [
        DatedCashFlow(
          date: DateTime(2024, 1, 1),
          amount: -10000.0,
        ),
        DatedCashFlow(
          date: DateTime(2025, 1, 1),
          amount: 11200.0,
        ),
      ];

      final xirr = FinancialCalculator.calculateXirr(cashFlows);
      expect(xirr, isNotNull);
      // 366 days in leap year 2024 -> ~11.96%
      expect(xirr!, closeTo(11.96, 0.1));
    });

    test('calculateXirr handles multi-installment SIP scenario', () {
      // 3 monthly installments of ₹10,000, total ₹30,000. Current value ₹33,000.
      final cashFlows = [
        DatedCashFlow(
          date: DateTime(2024, 1, 1),
          amount: -10000.0,
        ),
        DatedCashFlow(
          date: DateTime(2024, 2, 1),
          amount: -10000.0,
        ),
        DatedCashFlow(
          date: DateTime(2024, 3, 1),
          amount: -10000.0,
        ),
        DatedCashFlow(
          date: DateTime(2024, 7, 1),
          amount: 33000.0,
        ),
      ];

      final xirr = FinancialCalculator.calculateXirr(cashFlows);
      expect(xirr, isNotNull);
      expect(xirr! > 0, isTrue);
    });

    test(
        'calculateXirr returns null for invalid cash flows or insufficient duration',
        () {
      // Empty or single cash flow
      expect(FinancialCalculator.calculateXirr([]), isNull);
      expect(
        FinancialCalculator.calculateXirr([
          DatedCashFlow(date: DateTime(2024, 1, 1), amount: -5000),
        ]),
        isNull,
      );

      // All positive or all negative
      expect(
        FinancialCalculator.calculateXirr([
          DatedCashFlow(date: DateTime(2024, 1, 1), amount: 5000),
          DatedCashFlow(date: DateTime(2024, 2, 1), amount: 6000),
        ]),
        isNull,
      );

      // Same date (0 days)
      expect(
        FinancialCalculator.calculateXirr([
          DatedCashFlow(date: DateTime(2024, 1, 1), amount: -5000),
          DatedCashFlow(date: DateTime(2024, 1, 1), amount: 5500),
        ]),
        isNull,
      );
    });
  });
}
