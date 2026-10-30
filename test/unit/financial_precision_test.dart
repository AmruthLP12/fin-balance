import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/database/precision/financial_precision.dart';

void main() {
  group('FinancialPrecision', () {
    test('converts rupees to paise and back with exact precision', () {
      expect(FinancialPrecision.rupeesToPaise(5000.0), equals(500000));
      expect(FinancialPrecision.rupeesToPaise(1250.75), equals(125075));
      expect(FinancialPrecision.paiseToRupees(500000), equals(5000.0));
      expect(FinancialPrecision.paiseToRupees(125075), equals(1250.75));
    });

    test('converts units to micro-units and back with 6 decimal places', () {
      expect(FinancialPrecision.unitsToMicroUnits(10.5), equals(10500000));
      expect(
          FinancialPrecision.unitsToMicroUnits(125.456789), equals(125456789));
      expect(FinancialPrecision.microUnitsToUnits(10500000), equals(10.5));
      expect(FinancialPrecision.microUnitsToUnits(125456789),
          closeTo(125.456789, 0.000001));
    });

    test('converts NAV to micro-paise and back with 4 decimal places', () {
      expect(FinancialPrecision.navToMicroPaise(125.4560), equals(125456000));
      expect(FinancialPrecision.microPaiseToNav(125456000), equals(125.4560));
    });

    test(
        'calculates units purchased from amount in paise and NAV in micro-paise without float drift',
        () {
      // Investment: ₹5,000.00 (500,000 paise)
      // NAV: ₹100.0000 (100,000,000 micro-paise)
      // Expected Units: 50.0 units (50,000,000 micro-units)
      final units = FinancialPrecision.calculateUnitsPurchased(
        amountPaise: 500000,
        navMicroPaise: 100000000,
      );
      expect(units, equals(50000000));
      expect(FinancialPrecision.microUnitsToUnits(units), equals(50.0));
    });

    test('calculates valuation in paise from units and NAV', () {
      // Units: 50.0 units (50,000,000 micro-units)
      // NAV: ₹120.5000 (120,500,000 micro-paise)
      // Expected Value: 50 * 120.50 = ₹6,025.00 = 602,500 paise
      final valuePaise = FinancialPrecision.calculateValuationPaise(
        unitCountMicroUnits: 50000000,
        navMicroPaise: 120500000,
      );
      expect(valuePaise, equals(602500));
      expect(FinancialPrecision.paiseToRupees(valuePaise), equals(6025.0));
    });
  });
}
