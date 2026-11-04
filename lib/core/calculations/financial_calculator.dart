import 'dart:math' as math;
import '../../database/app_database.dart';
import '../../database/precision/financial_precision.dart';

/// Represents a cash flow on a specific calendar date.
/// Outflows (investments) have negative amounts; inflows (redemptions, current valuation) have positive amounts.
class DatedCashFlow {
  final DateTime date;
  final double amount;

  const DatedCashFlow({
    required this.date,
    required this.amount,
  });

  @override
  String toString() => 'DatedCashFlow(${date.toIso8601String()}, $amount)';
}

/// Unified financial calculation engine for FinBalance.
/// Provides high-precision calculation of P&L, Absolute Return, and dated cash-flow XIRR (Newton-Raphson).
class FinancialCalculator {
  FinancialCalculator._();

  /// Calculate Absolute Return percentage.
  ///
  /// Returns ((currentValuation - invested) / invested) * 100 if invested > 0, else 0.0.
  static double calculateAbsoluteReturn({
    required int investedPaise,
    required int currentValuationPaise,
  }) {
    if (investedPaise <= 0) return 0.0;
    return ((currentValuationPaise - investedPaise) / investedPaise) * 100.0;
  }

  /// Calculate Profit / Loss in integer Paise.
  static int calculateProfitLossPaise({
    required int investedPaise,
    required int currentValuationPaise,
  }) {
    return currentValuationPaise - investedPaise;
  }

  /// Calculate XIRR (Extended Internal Rate of Return) from a series of dated cash flows.
  ///
  /// Uses the Newton-Raphson numerical method to solve for `r` in:
  ///   sum( C_i / (1 + r)^((d_i - d_0) / 365) ) = 0
  ///
  /// Returns annual rate as a percentage (e.g. 15.4 for 15.4%), or `null` if:
  /// - Fewer than 2 cash flows exist.
  /// - All cash flows are of the same sign (no positive or no negative).
  /// - Time span between first and last cash flow is less than [minHoldingDays] (default 1 day).
  /// - Method does not converge within [maxIterations].
  static double? calculateXirr(
    List<DatedCashFlow> cashFlows, {
    double guess = 0.1,
    int maxIterations = 100,
    double tolerance = 1e-6,
    int minHoldingDays = 1,
  }) {
    if (cashFlows.length < 2) return null;

    // Check for both positive and negative cash flows
    bool hasPositive = false;
    bool hasNegative = false;
    for (final cf in cashFlows) {
      if (cf.amount > 0) hasPositive = true;
      if (cf.amount < 0) hasNegative = true;
    }
    if (!hasPositive || !hasNegative) return null;

    // Sort cash flows ascending by date
    final sorted = List<DatedCashFlow>.from(cashFlows)
      ..sort((a, b) => a.date.compareTo(b.date));

    final d0 = sorted.first.date;
    final dn = sorted.last.date;
    final totalDays = dn.difference(d0).inDays;
    if (totalDays < minHoldingDays) return null;

    // Precalculate time fractions in years: (d_i - d_0) / 365.0
    final timeFractions = sorted.map((cf) {
      return cf.date.difference(d0).inDays / 365.0;
    }).toList();

    double r = guess;

    for (int iter = 0; iter < maxIterations; iter++) {
      if (r <= -1.0) {
        r = -0.999;
      }

      double fValue = 0.0;
      double fDerivative = 0.0;

      for (int i = 0; i < sorted.length; i++) {
        final c = sorted[i].amount;
        final t = timeFractions[i];

        if (t == 0.0) {
          fValue += c;
          continue;
        }

        final denom = math.pow(1.0 + r, t).toDouble();
        if (denom == 0.0 || denom.isNaN || denom.isInfinite) {
          return null;
        }

        fValue += c / denom;
        fDerivative -= (t * c) / (denom * (1.0 + r));
      }

      if (fDerivative.abs() < 1e-12) {
        // Flat derivative, unable to proceed with Newton-Raphson step
        return null;
      }

      final double step = fValue / fDerivative;
      r -= step;

      // Bound r to reasonable financial rate range (-99% to +10,000%)
      if (r < -0.99) r = -0.99;
      if (r > 100.0) r = 100.0;

      if (step.abs() < tolerance && fValue.abs() < tolerance * 1000) {
        final ratePercent = r * 100.0;
        if (ratePercent.isNaN || ratePercent.isInfinite) return null;
        return ratePercent;
      }
    }

    return null;
  }

  /// Calculate XIRR for a specific holding using its recorded transactions and current valuation.
  ///
  /// Outflows (investor cash out): Purchases, SIP investments, and Switch In (with charges added).
  /// Inflows (investor cash in): Redemptions, SWP withdrawals, Dividend Payouts, and Switch Out (with charges deducted).
  /// Dividend reinvestments: Internal conversion, external cash flow is 0.
  /// Current valuation is treated as a terminal positive cash flow on [valuationDate] (defaults to now).
  static double? calculateHoldingXirr({
    required List<Transaction> transactions,
    required int currentValuationPaise,
    DateTime? valuationDate,
  }) =>
      _xirrFor(transactions, currentValuationPaise, valuationDate,
          skipLinkedSwitches: false);

  /// Calculate portfolio-wide XIRR across multiple holdings and transactions.
  ///
  /// Switches that are linked to a paired transaction are internal to the portfolio and cancel out,
  /// so only unlinked (external) switches count.
  static double? calculatePortfolioXirr({
    required List<Transaction> transactions,
    required int totalValuationPaise,
    DateTime? valuationDate,
  }) =>
      _xirrFor(transactions, totalValuationPaise, valuationDate,
          skipLinkedSwitches: true);

  static double? _xirrFor(
    List<Transaction> transactions,
    int valuationPaise,
    DateTime? valuationDate, {
    required bool skipLinkedSwitches,
  }) {
    if (transactions.isEmpty || valuationPaise <= 0) return null;

    final cashFlows = <DatedCashFlow>[];

    for (final tx in transactions) {
      final type = tx.transactionType.toLowerCase();
      final isSwitch = type == 'switch_in' || type == 'switch_out';
      if (skipLinkedSwitches && isSwitch && tx.linkedTransactionId != null) {
        continue;
      }

      final int paise;
      if (type == 'investment_purchase' ||
          type == 'sip_investment' ||
          type == 'switch_in') {
        // Outflow from investor: gross amount + charges
        paise = -(tx.amountPaise + tx.chargesPaise);
      } else if (type == 'redemption' ||
          type == 'swp_withdrawal' ||
          type == 'switch_out' ||
          type == 'investment_sale' ||
          type == 'dividend_payout') {
        // Inflow to investor: gross amount - charges (gross if charges exceed it)
        final net = tx.amountPaise - tx.chargesPaise;
        paise = net > 0 ? net : tx.amountPaise;
      } else {
        // dividend_reinvestment converts internally to units: no external cash flow
        continue;
      }

      if (paise != 0) {
        cashFlows.add(DatedCashFlow(
          date: tx.transactionDate,
          amount: FinancialPrecision.paiseToRupees(paise),
        ));
      }
    }

    if (cashFlows.isEmpty) return null;

    // Terminal cash flow on valuation date
    cashFlows.add(DatedCashFlow(
      date: valuationDate ?? DateTime.now(),
      amount: FinancialPrecision.paiseToRupees(valuationPaise),
    ));

    return calculateXirr(cashFlows);
  }
}
