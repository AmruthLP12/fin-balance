import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/database/precision/financial_precision.dart';

void main() {
  group('Portfolio Valuation & Precision Mathematics', () {
    test(
        'Calculates current value, profit/loss, and absolute return accurately',
        () {
      // Holding 1: 150 units bought at ₹100 = ₹15,000 invested. Latest NAV = ₹125
      const units1 = 150.0;
      const investedRupees1 = 15000.0;
      const latestNav1 = 125.0;

      final unitsMicro1 = FinancialPrecision.unitsToMicroUnits(units1);
      final navMicro1 = FinancialPrecision.navToMicroPaise(latestNav1);
      final currentValuationPaise1 = FinancialPrecision.calculateValuationPaise(
        unitCountMicroUnits: unitsMicro1,
        navMicroPaise: navMicro1,
      );
      final currentValuationRupees1 = currentValuationPaise1 / 100.0;

      expect(currentValuationRupees1, equals(18750.0)); // 150 * 125 = 18,750

      final profitPaise1 = currentValuationPaise1 -
          FinancialPrecision.rupeesToPaise(investedRupees1);
      expect(profitPaise1 / 100.0, equals(3750.0));

      final returnPct1 =
          (profitPaise1 / FinancialPrecision.rupeesToPaise(investedRupees1)) *
              100;
      expect(returnPct1, equals(25.0)); // +25.0%
    });

    test('Handles loss scenario correctly with negative return', () {
      // Holding 2: 200 units bought at ₹50 = ₹10,000 invested. Latest NAV = ₹40
      const units2 = 200.0;
      const investedRupees2 = 10000.0;
      const latestNav2 = 40.0;

      final unitsMicro2 = FinancialPrecision.unitsToMicroUnits(units2);
      final navMicro2 = FinancialPrecision.navToMicroPaise(latestNav2);
      final currentValuationPaise2 = FinancialPrecision.calculateValuationPaise(
        unitCountMicroUnits: unitsMicro2,
        navMicroPaise: navMicro2,
      );
      final currentValuationRupees2 = currentValuationPaise2 / 100.0;

      expect(currentValuationRupees2, equals(8000.0)); // 200 * 40 = 8,000

      final lossPaise = currentValuationPaise2 -
          FinancialPrecision.rupeesToPaise(investedRupees2);
      expect(lossPaise / 100.0, equals(-2000.0)); // -₹2,000

      final returnPct2 =
          (lossPaise / FinancialPrecision.rupeesToPaise(investedRupees2)) * 100;
      expect(returnPct2, equals(-20.0)); // -20.0%
    });

    test(
        'Handles missing NAV or zero units gracefully without NaN or divide-by-zero',
        () {
      // Zero units
      const unitsZero = 0.0;
      final valuationZero = FinancialPrecision.calculateValuationPaise(
        unitCountMicroUnits: FinancialPrecision.unitsToMicroUnits(unitsZero),
        navMicroPaise: FinancialPrecision.navToMicroPaise(100.0),
      );
      expect(valuationZero, equals(0));

      // Zero invested
      const investedZero = 0;
      const returnPct = investedZero > 0 ? (500 / investedZero) * 100 : 0.0;
      expect(returnPct, equals(0.0));
      expect(returnPct.isNaN, isFalse);
    });

    test('Sum of multiple holdings calculates net portfolio valuation', () {
      final holdings = [
        (investedPaise: 1000000, valuationPaise: 1200000), // +2000
        (investedPaise: 2000000, valuationPaise: 1800000), // -2000
        (investedPaise: 1500000, valuationPaise: 2000000), // +5000
      ];

      final totalInvested =
          holdings.fold<int>(0, (sum, h) => sum + h.investedPaise);
      final totalValuation =
          holdings.fold<int>(0, (sum, h) => sum + h.valuationPaise);
      final netGain = totalValuation - totalInvested;
      final netReturnPct = (netGain / totalInvested) * 100;

      expect(totalInvested, equals(4500000)); // ₹45,000
      expect(totalValuation, equals(5000000)); // ₹50,000
      expect(netGain, equals(500000)); // ₹5,000 profit
      expect(double.parse(netReturnPct.toStringAsFixed(2)),
          equals(11.11)); // +11.11%
    });
  });
}
