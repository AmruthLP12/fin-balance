import '../../core/formatting/currency_formatter.dart';
import '../../core/formatting/date_formatter.dart';
import '../../database/app_database.dart';
import '../../database/precision/financial_precision.dart';

/// Helper service that generates a concise, point-wise human-readable narrative of an investment's lifecycle
/// based on authoritative database records (holdings, SIP plans, SWP plans, schedule periods, and transactions).
class InvestmentLifecycleSummary {
  InvestmentLifecycleSummary._();

  /// Generates chronological, point-wise lifecycle events for an investment.
  /// Only events that actually exist are included.
  static List<String> generateLifecycleEvents({
    required FinancialItem holding,
    required List<SipPlan> sips,
    required List<SipSchedulePeriod> schedulePeriods,
    List<SwpPlan> swps = const [],
    List<SwpSchedulePeriod> swpPeriods = const [],
    required List<Transaction> transactions,
  }) {
    final events = <({DateTime date, String description})>[];

    // 1. Initial holding creation / start date if non-SIP purchase
    final purchases = transactions
        .where((t) => t.transactionType.toLowerCase() == 'investment_purchase')
        .toList();

    for (final p in purchases) {
      final amtStr = CurrencyFormatter.formatPaise(p.amountPaise);
      final unitsStr = p.unitsMicroUnits != null && p.unitsMicroUnits! > 0
          ? ' (${FinancialPrecision.microUnitsToUnits(p.unitsMicroUnits!).toStringAsFixed(3)} units)'
          : '';
      events.add((
        date: p.transactionDate,
        description:
            'One-time investment on ${DateFormatter.formatDate(p.transactionDate)} · $amtStr$unitsStr',
      ));
    }

    // 2. SIP Schedule Periods Lifecycle
    if (schedulePeriods.isNotEmpty) {
      final sortedPeriods = List<SipSchedulePeriod>.from(schedulePeriods)
        ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));

      for (int i = 0; i < sortedPeriods.length; i++) {
        final p = sortedPeriods[i];
        final amtStr = CurrencyFormatter.formatPaise(p.amountPaise);
        final freqStr = p.frequency.toLowerCase();
        final fromStr = DateFormatter.formatDate(p.effectiveFrom);

        if (i == 0) {
          events.add((
            date: p.effectiveFrom,
            description: 'Start on $fromStr · $amtStr / $freqStr',
          ));
        } else {
          events.add((
            date: p.effectiveFrom,
            description: 'Period revised on $fromStr · $amtStr / $freqStr',
          ));
        }

        if (p.effectiveTo != null) {
          events.add((
            date: p.effectiveTo!,
            description:
                'Previous SIP period closed on ${DateFormatter.formatDate(p.effectiveTo!)}',
          ));
        }
      }
    } else if (sips.isNotEmpty) {
      for (final sip in sips) {
        final sipStart = DateFormatter.formatDate(sip.startDate);
        events.add((
          date: sip.startDate,
          description: 'SIP started on $sipStart (${sip.status})',
        ));
        if (sip.endDate != null) {
          events.add((
            date: sip.endDate!,
            description:
                'SIP closed on ${DateFormatter.formatDate(sip.endDate!)}',
          ));
        }
      }
    }

    // 3. SWP Schedule Periods Lifecycle
    if (swpPeriods.isNotEmpty) {
      final sortedSwpPeriods = List<SwpSchedulePeriod>.from(swpPeriods)
        ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));

      for (int i = 0; i < sortedSwpPeriods.length; i++) {
        final p = sortedSwpPeriods[i];
        final valStr = p.amountPaise != null
            ? CurrencyFormatter.formatPaise(p.amountPaise!)
            : (p.unitsMicroUnits != null
                ? '${FinancialPrecision.microUnitsToUnits(p.unitsMicroUnits!).toStringAsFixed(3)} units'
                : 'configured amount');
        final freqStr = p.frequency.toLowerCase();
        final fromStr = DateFormatter.formatDate(p.effectiveFrom);

        if (i == 0) {
          events.add((
            date: p.effectiveFrom,
            description: 'SWP started on $fromStr · $valStr / $freqStr',
          ));
        } else {
          events.add((
            date: p.effectiveFrom,
            description: 'SWP revised on $fromStr · $valStr / $freqStr',
          ));
        }

        if (p.effectiveTo != null) {
          events.add((
            date: p.effectiveTo!,
            description:
                'SWP period closed on ${DateFormatter.formatDate(p.effectiveTo!)}',
          ));
        }
      }
    }

    // 4. Redemptions / SWP withdrawals
    final redemptions = transactions.where((t) {
      final type = t.transactionType.toLowerCase();
      return type == 'redemption' ||
          type == 'swp_withdrawal' ||
          type == 'investment_sale';
    }).toList();

    for (final r in redemptions) {
      final isSwp = r.transactionType.toLowerCase() == 'swp_withdrawal';
      final units = r.unitsMicroUnits != null
          ? FinancialPrecision.microUnitsToUnits(r.unitsMicroUnits!)
              .toStringAsFixed(3)
          : null;
      final amt = CurrencyFormatter.formatPaise(r.amountPaise);
      final dateStr = DateFormatter.formatDate(r.transactionDate);

      events.add((
        date: r.transactionDate,
        description: isSwp
            ? 'SWP withdrawal on $dateStr · $amt${units != null ? " ($units units)" : ""}'
            : 'Redemption on $dateStr · $amt${units != null ? " ($units units)" : ""}',
      ));
    }

    // 5. Dividends & Switches
    for (final tx in transactions) {
      final type = tx.transactionType.toLowerCase();
      final dateStr = DateFormatter.formatDate(tx.transactionDate);
      if (type == 'dividend_reinvestment') {
        final units = tx.unitsMicroUnits != null
            ? FinancialPrecision.microUnitsToUnits(tx.unitsMicroUnits!)
                .toStringAsFixed(3)
            : 'units';
        events.add((
          date: tx.transactionDate,
          description: 'Dividend reinvested on $dateStr · $units added',
        ));
      } else if (type == 'dividend_payout') {
        final amt = CurrencyFormatter.formatPaise(tx.amountPaise);
        events.add((
          date: tx.transactionDate,
          description: 'Dividend payout on $dateStr · $amt',
        ));
      } else if (type == 'switch_in') {
        final amt = CurrencyFormatter.formatPaise(tx.amountPaise);
        final notes = tx.notes;
        final detail = (notes != null && notes.contains('from'))
            ? notes
            : 'Switched in on $dateStr · $amt';
        events.add((
          date: tx.transactionDate,
          description: detail,
        ));
      } else if (type == 'switch_out') {
        final amt = CurrencyFormatter.formatPaise(tx.amountPaise);
        final notes = tx.notes;
        final detail = (notes != null && notes.contains('to'))
            ? notes
            : 'Switched out on $dateStr · $amt';
        events.add((
          date: tx.transactionDate,
          description: detail,
        ));
      }
    }

    if (events.isEmpty) {
      return [
        'Holding record created on ${DateFormatter.formatDate(holding.startDate ?? holding.createdAt)}.',
      ];
    }

    // Sort chronologically (oldest first)
    events.sort((a, b) => a.date.compareTo(b.date));

    return events.map((e) => e.description).toList();
  }

  /// Backward-compatible single narrative summary generator.
  static String generateSummary({
    required FinancialItem holding,
    required List<SipPlan> sips,
    required List<SipSchedulePeriod> schedulePeriods,
    required List<Transaction> transactions,
  }) {
    final events = generateLifecycleEvents(
      holding: holding,
      sips: sips,
      schedulePeriods: schedulePeriods,
      transactions: transactions,
    );
    return events.join(' ');
  }
}
