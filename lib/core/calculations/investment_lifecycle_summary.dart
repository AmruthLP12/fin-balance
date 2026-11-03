import '../../core/formatting/currency_formatter.dart';
import '../../core/formatting/date_formatter.dart';
import '../../database/app_database.dart';
import '../../database/precision/financial_precision.dart';

/// Helper service that generates a concise, human-readable narrative of an investment's lifecycle
/// based on authoritative database records (holdings, SIP plans, schedule periods, and transactions).
class InvestmentLifecycleSummary {
  InvestmentLifecycleSummary._();

  /// Generate a readable lifecycle summary for a mutual fund holding.
  static String generateSummary({
    required FinancialItem holding,
    required List<SipPlan> sips,
    required List<SipSchedulePeriod> schedulePeriods,
    required List<Transaction> transactions,
  }) {
    final parts = <String>[];

    // 1. Initial Start
    final startDate = holding.startDate ??
        (transactions.isNotEmpty
            ? transactions
                .map((t) => t.transactionDate)
                .reduce((a, b) => a.isBefore(b) ? a : b)
            : null);

    if (startDate != null) {
      if (holding.initialValuePaise > 0) {
        parts.add(
          'Investment initiated on ${DateFormatter.formatDate(startDate)} with an initial contribution of ${CurrencyFormatter.formatPaise(holding.initialValuePaise)}.',
        );
      } else {
        parts.add(
            'Investment initiated on ${DateFormatter.formatDate(startDate)}.');
      }
    }

    // 2. SIP Schedule Periods Lifecycle
    if (sips.isNotEmpty) {
      // Sort schedule periods chronologically
      final sortedPeriods = List<SipSchedulePeriod>.from(schedulePeriods)
        ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));

      if (sortedPeriods.isNotEmpty) {
        for (int i = 0; i < sortedPeriods.length; i++) {
          final p = sortedPeriods[i];
          final amtStr = CurrencyFormatter.formatPaise(p.amountPaise);
          final freqStr = p.frequency.toLowerCase();
          final fromStr = DateFormatter.formatDate(p.effectiveFrom);

          if (i == 0 && sortedPeriods.length == 1) {
            if (p.effectiveTo != null) {
              final toStr = DateFormatter.formatDate(p.effectiveTo!);
              parts.add(
                'Ran a $freqStr SIP of $amtStr from $fromStr until closing on $toStr.',
              );
            } else {
              parts.add(
                'Running an active $freqStr SIP of $amtStr starting on $fromStr.',
              );
            }
          } else if (i == 0) {
            // First period in multi-period history
            final toStr = p.effectiveTo != null
                ? ' until ${DateFormatter.formatDate(p.effectiveTo!)}'
                : '';
            parts.add(
              'Started with an initial $freqStr SIP of $amtStr on $fromStr$toStr.',
            );
          } else {
            // Subsequent revised periods
            final statusLabel = p.effectiveTo != null
                ? 'closed on ${DateFormatter.formatDate(p.effectiveTo!)}'
                : 'currently active';
            parts.add(
              'A revised $freqStr SIP of $amtStr started on $fromStr ($statusLabel).',
            );
          }
        }
      } else {
        // Fallback to master SIP record
        for (final sip in sips) {
          final sipStart = DateFormatter.formatDate(sip.startDate);
          if (sip.endDate != null) {
            parts.add(
              'SIP (${sip.name}) was active from $sipStart to ${DateFormatter.formatDate(sip.endDate!)} (${sip.status}).',
            );
          } else {
            parts
                .add('SIP (${sip.name}) started on $sipStart (${sip.status}).');
          }
        }
      }
    }

    // 3. Transactions Breakdown
    if (transactions.isNotEmpty) {
      int purchases = 0;
      int sipsCount = 0;
      int redemptions = 0;
      int divReinvest = 0;
      int divPayout = 0;
      int switches = 0;
      int redeemedUnitsMicro = 0;
      int redeemedAmountPaise = 0;

      for (final tx in transactions) {
        final type = tx.transactionType.toLowerCase();
        if (type == 'investment_purchase') {
          purchases++;
        } else if (type == 'sip_investment') {
          sipsCount++;
        } else if (type == 'redemption' ||
            type == 'swp_withdrawal' ||
            type == 'investment_sale') {
          redemptions++;
          redeemedUnitsMicro += (tx.unitsMicroUnits ?? 0);
          redeemedAmountPaise += (tx.amountPaise - (tx.chargesPaise));
        } else if (type == 'dividend_reinvestment') {
          divReinvest++;
        } else if (type == 'dividend_payout') {
          divPayout++;
        } else if (type == 'switch_in' || type == 'switch_out') {
          switches++;
        }
      }

      final txParts = <String>[];
      if (purchases > 0 || sipsCount > 0) {
        final totalBuys = purchases + sipsCount;
        txParts.add('$totalBuys purchase transaction(s)');
      }
      if (redemptions > 0) {
        final units = FinancialPrecision.microUnitsToUnits(redeemedUnitsMicro);
        final amt = CurrencyFormatter.formatPaise(redeemedAmountPaise);
        txParts.add(
            '$redemptions redemption(s) totaling ${units.toStringAsFixed(3)} units ($amt net proceeds)');
      }
      if (divReinvest > 0) {
        txParts.add('$divReinvest dividend reinvestment(s)');
      }
      if (divPayout > 0) {
        txParts.add('$divPayout dividend payout(s)');
      }
      if (switches > 0) {
        txParts.add('$switches switch transaction(s)');
      }

      if (txParts.isNotEmpty) {
        parts.add('Transaction history includes: ${txParts.join(', ')}.');
      }
    }

    if (parts.isEmpty) {
      return 'Holding record created. No historical investment schedule or transactions recorded yet.';
    }

    return parts.join(' ');
  }
}
