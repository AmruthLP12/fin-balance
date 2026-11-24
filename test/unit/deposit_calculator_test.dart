import 'package:finbalance/data/assets/deposit_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('non-cumulative FD includes simple interest in its maturity amount', () {
    final estimate = estimateDeposit(
      installmentRupees: 10000,
      rateBasisPoints: 750,
      tenureMonths: 60,
      compoundingMonths: 3,
      recurring: false,
      cumulative: false,
    );

    expect(estimate.contributionsPaise, 1000000);
    expect(estimate.interestPaise, 375000);
    expect(estimate.maturityPaise, 1375000);
  });

  test('RD estimate includes each monthly installment', () {
    final estimate = estimateDeposit(
      installmentRupees: 1000,
      rateBasisPoints: 650,
      tenureMonths: 12,
      compoundingMonths: 3,
      recurring: true,
      cumulative: true,
    );

    expect(estimate.contributionsPaise, 1200000);
    expect(estimate.maturityPaise, greaterThan(estimate.contributionsPaise));
    expect(estimate.interestPaise,
        estimate.maturityPaise - estimate.contributionsPaise);
  });
}
