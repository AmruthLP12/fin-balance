import '../../core/formatting/currency_formatter.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/scheduling/investment_schedule_service.dart';
import '../../database/app_database.dart';
import '../../database/precision/financial_precision.dart';

enum LifecycleKind {
  created,
  oneTime,
  sipStart,
  sipRevised,
  sipEnd,
  swpStart,
  swpRevised,
  swpEnd,
  redemption,
  swpWithdrawal,
  dividendReinvested,
  dividendReceived,
  switchIn,
  switchOut,
}

/// One dated step in an investment's story: a short [title] plus optional [detail].
class LifecycleEvent {
  final DateTime date;
  final LifecycleKind kind;
  final String title;
  final String? detail;

  const LifecycleEvent({
    required this.date,
    required this.kind,
    required this.title,
    this.detail,
  });

  /// Single-line form, e.g. `01 Jan 2024 · SIP started — ₹1,000.00 · monthly`.
  String get headline =>
      '${DateFormatter.formatDate(date)} · $title${detail != null ? ' — $detail' : ''}';
}

/// At-a-glance totals shown above the lifecycle timeline.
class LifecycleOverview {
  final String status;
  final DateTime heldSince;
  final String heldFor;
  final int investedPaise;
  final int currentValuePaise;
  final double unitsHeld;
  final int sipInstallments;
  final int withdrawnPaise;
  final int dividendsPaise;

  const LifecycleOverview({
    required this.status,
    required this.heldSince,
    required this.heldFor,
    required this.investedPaise,
    required this.currentValuePaise,
    required this.unitsHeld,
    required this.sipInstallments,
    required this.withdrawnPaise,
    required this.dividendsPaise,
  });
}

/// Builds the lifecycle of an investment from authoritative database records
/// (holding, SIP/SWP plans and periods, transactions). Only things that happened
/// or are configured are reported; SIP installments are rolled up per period
/// rather than listed one by one.
class InvestmentLifecycleSummary {
  InvestmentLifecycleSummary._();

  static bool _isSipTx(Transaction t) =>
      t.transactionType.toLowerCase() == 'sip_investment' ||
      t.sipPlanId != null ||
      t.source == 'sip_installment' ||
      t.source == 'simulated_sip';

  static bool _isRedemptionLike(String type) =>
      type == 'redemption' ||
      type == 'swp_withdrawal' ||
      type == 'investment_sale';

  static String _units(int micro) =>
      FinancialPrecision.microUnitsToUnits(micro).toStringAsFixed(3);

  static String _unitsSuffix(Transaction t) =>
      t.unitsMicroUnits != null && t.unitsMicroUnits! > 0
          ? ' · ${_units(t.unitsMicroUnits!)} units'
          : '';

  static DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// Chronological events, oldest first.
  static List<LifecycleEvent> buildTimeline({
    required FinancialItem holding,
    required List<SipPlan> sips,
    required List<SipSchedulePeriod> schedulePeriods,
    List<SwpPlan> swps = const [],
    List<SwpSchedulePeriod> swpPeriods = const [],
    required List<Transaction> transactions,
    DateTime? asOf,
  }) {
    final today = _day(asOf ?? DateTime.now());
    final events = <LifecycleEvent>[];

    // Split transactions: SIP-origin ones are rolled up per period.
    final sipTxs = transactions.where(_isSipTx).toList();
    final sortedSipPeriods = List<SipSchedulePeriod>.from(schedulePeriods)
      ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));

    SipSchedulePeriod? periodFor(DateTime date) {
      final d = _day(date);
      for (final p in sortedSipPeriods.reversed) {
        if (!d.isBefore(_day(p.effectiveFrom))) return p;
      }
      return sortedSipPeriods.firstOrNull;
    }

    final rollup = <int, List<Transaction>>{};
    for (final t in sipTxs) {
      final p = periodFor(t.transactionDate);
      if (p != null) rollup.putIfAbsent(p.id, () => []).add(t);
    }

    String sipProgress(SipSchedulePeriod p) {
      final txs = rollup[p.id];
      if (txs == null || txs.isEmpty) return '';
      final amount = txs.fold<int>(0, (s, t) => s + t.amountPaise);
      final units = txs.fold<int>(0, (s, t) => s + (t.unitsMicroUnits ?? 0));
      final n = txs.length;
      return ' · $n installment${n == 1 ? '' : 's'} invested '
          '(${CurrencyFormatter.formatPaise(amount)}'
          '${units > 0 ? ', ${_units(units)} units' : ''})';
    }

    // 1. One-time purchases
    for (final t in transactions) {
      if (t.transactionType.toLowerCase() != 'investment_purchase' ||
          _isSipTx(t)) {
        continue;
      }
      final nav = t.unitPriceMicroPaise != null && t.unitPriceMicroPaise! > 0
          ? ' · NAV ₹${FinancialPrecision.microPaiseToNav(t.unitPriceMicroPaise!).toStringAsFixed(4)}'
          : '';
      events.add(LifecycleEvent(
        date: t.transactionDate,
        kind: LifecycleKind.oneTime,
        title: 'One-time investment',
        detail:
            '${CurrencyFormatter.formatPaise(t.amountPaise)}${_unitsSuffix(t)}$nav',
      ));
    }

    // 2. SIP schedule periods
    if (sortedSipPeriods.isNotEmpty) {
      for (int i = 0; i < sortedSipPeriods.length; i++) {
        final p = sortedSipPeriods[i];
        final plan =
            ScheduleFrequency.fromString(p.frequency).label.toLowerCase();
        final until =
            p.effectiveTo != null && _day(p.effectiveTo!).isAfter(today)
                ? ' · until ${DateFormatter.formatDate(p.effectiveTo!)}'
                : '';
        events.add(LifecycleEvent(
          date: p.effectiveFrom,
          kind: i == 0 ? LifecycleKind.sipStart : LifecycleKind.sipRevised,
          title: i == 0 ? 'SIP started' : 'SIP revised',
          detail:
              '${CurrencyFormatter.formatPaise(p.amountPaise)} · $plan$until${sipProgress(p)}',
        ));

        final end = p.effectiveTo;
        final next =
            i + 1 < sortedSipPeriods.length ? sortedSipPeriods[i + 1] : null;
        final replaced = next != null &&
            _day(next.effectiveFrom)
                    .difference(_day(end ?? next.effectiveFrom))
                    .inDays <=
                1;
        if (end != null && !_day(end).isAfter(today) && !replaced) {
          final stopped = p.status == 'closed' || p.status == 'superseded';
          events.add(LifecycleEvent(
            date: end,
            kind: LifecycleKind.sipEnd,
            title: stopped ? 'SIP stopped' : 'SIP completed',
          ));
        }
      }
    } else {
      for (final sip in sips) {
        events.add(LifecycleEvent(
          date: sip.startDate,
          kind: LifecycleKind.sipStart,
          title: 'SIP started',
          detail: sip.status,
        ));
        if (sip.endDate != null && !_day(sip.endDate!).isAfter(today)) {
          events.add(LifecycleEvent(
            date: sip.endDate!,
            kind: LifecycleKind.sipEnd,
            title: sip.status == 'completed' ? 'SIP completed' : 'SIP stopped',
          ));
        }
      }
    }

    // 3. SWP schedule periods
    final sortedSwp = List<SwpSchedulePeriod>.from(swpPeriods)
      ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    for (int i = 0; i < sortedSwp.length; i++) {
      final p = sortedSwp[i];
      final value = p.amountPaise != null
          ? CurrencyFormatter.formatPaise(p.amountPaise!)
          : (p.unitsMicroUnits != null
              ? '${_units(p.unitsMicroUnits!)} units'
              : 'configured amount');
      final freq =
          ScheduleFrequency.fromString(p.frequency).label.toLowerCase();
      events.add(LifecycleEvent(
        date: p.effectiveFrom,
        kind: i == 0 ? LifecycleKind.swpStart : LifecycleKind.swpRevised,
        title: i == 0 ? 'SWP started' : 'SWP revised',
        detail: '$value · $freq',
      ));

      final end = p.effectiveTo;
      final next = i + 1 < sortedSwp.length ? sortedSwp[i + 1] : null;
      final replaced = next != null &&
          _day(next.effectiveFrom)
                  .difference(_day(end ?? next.effectiveFrom))
                  .inDays <=
              1;
      if (end != null && !_day(end).isAfter(today) && !replaced) {
        final stopped = p.status == 'closed' || p.status == 'superseded';
        events.add(LifecycleEvent(
          date: end,
          kind: LifecycleKind.swpEnd,
          title: stopped ? 'SWP stopped' : 'SWP completed',
        ));
      }
    }

    // 4. Withdrawals, dividends and switches
    for (final t in transactions) {
      final type = t.transactionType.toLowerCase();
      final amount = CurrencyFormatter.formatPaise(t.amountPaise);
      if (_isRedemptionLike(type)) {
        final isSwp = type == 'swp_withdrawal';
        events.add(LifecycleEvent(
          date: t.transactionDate,
          kind: isSwp ? LifecycleKind.swpWithdrawal : LifecycleKind.redemption,
          title: isSwp ? 'SWP withdrawal' : 'Redemption',
          detail: '$amount${_unitsSuffix(t)}',
        ));
      } else if (type == 'dividend_reinvestment') {
        events.add(LifecycleEvent(
          date: t.transactionDate,
          kind: LifecycleKind.dividendReinvested,
          title: 'Dividend reinvested',
          detail: t.unitsMicroUnits != null
              ? '${_units(t.unitsMicroUnits!)} units added'
              : amount,
        ));
      } else if (type == 'dividend_payout') {
        events.add(LifecycleEvent(
          date: t.transactionDate,
          kind: LifecycleKind.dividendReceived,
          title: 'Dividend received',
          detail: amount,
        ));
      } else if (type == 'switch_in' || type == 'switch_out') {
        final isIn = type == 'switch_in';
        final note = t.notes;
        events.add(LifecycleEvent(
          date: t.transactionDate,
          kind: isIn ? LifecycleKind.switchIn : LifecycleKind.switchOut,
          title: isIn ? 'Switched in' : 'Switched out',
          detail: (note != null && note.contains(isIn ? 'from' : 'to'))
              ? '$amount · ${note.split('•').last.trim()}'
              : amount,
        ));
      }
    }

    if (events.isEmpty) {
      return [
        LifecycleEvent(
          date: holding.startDate ?? holding.createdAt,
          kind: LifecycleKind.created,
          title: 'Holding added',
        ),
      ];
    }

    // Stable chronological sort (ties keep insertion order).
    final indexed = events.indexed.toList()
      ..sort((a, b) {
        final c = a.$2.date.compareTo(b.$2.date);
        return c != 0 ? c : a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }

  static LifecycleOverview buildOverview({
    required FinancialItem holding,
    required List<SipSchedulePeriod> schedulePeriods,
    List<SwpSchedulePeriod> swpPeriods = const [],
    required List<Transaction> transactions,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final today = _day(now);

    var heldSince = holding.startDate ?? holding.createdAt;
    for (final t in transactions) {
      if (t.transactionDate.isBefore(heldSince)) heldSince = t.transactionDate;
    }

    var withdrawn = 0;
    var dividends = 0;
    var sipCount = 0;
    for (final t in transactions) {
      final type = t.transactionType.toLowerCase();
      if (_isSipTx(t)) sipCount++;
      if (_isRedemptionLike(type)) withdrawn += t.amountPaise - t.chargesPaise;
      if (type == 'dividend_payout') {
        dividends += t.amountPaise - t.chargesPaise;
      }
    }

    bool running(DateTime from, DateTime? to, String status) =>
        status == 'active' &&
        !_day(from).isAfter(today) &&
        (to == null || _day(to).isAfter(today));
    final sipRunning = schedulePeriods
        .any((p) => running(p.effectiveFrom, p.effectiveTo, p.status));
    final swpRunning = swpPeriods
        .any((p) => running(p.effectiveFrom, p.effectiveTo, p.status));

    final String status;
    if (holding.unitCountMicroUnits <= 0 && transactions.isNotEmpty) {
      status = 'Fully redeemed';
    } else if (sipRunning && swpRunning) {
      status = 'SIP + SWP running';
    } else if (sipRunning) {
      status = 'SIP running';
    } else if (swpRunning) {
      status = 'SWP running';
    } else {
      status = 'Holding';
    }

    return LifecycleOverview(
      status: status,
      heldSince: heldSince,
      heldFor: _duration(_day(heldSince), today),
      investedPaise: holding.initialValuePaise,
      currentValuePaise: holding.currentValuationPaise,
      unitsHeld:
          FinancialPrecision.microUnitsToUnits(holding.unitCountMicroUnits),
      sipInstallments: sipCount,
      withdrawnPaise: withdrawn,
      dividendsPaise: dividends,
    );
  }

  static String _duration(DateTime from, DateTime to) {
    if (!to.isAfter(from)) return 'today';
    var months = (to.year - from.year) * 12 + to.month - from.month;
    if (to.day < from.day) months--;
    if (months < 1) {
      final days = to.difference(from).inDays;
      return '$days day${days == 1 ? '' : 's'}';
    }
    final y = months ~/ 12;
    final m = months % 12;
    return [
      if (y > 0) '$y yr${y == 1 ? '' : 's'}',
      if (m > 0) '$m mo${m == 1 ? '' : 's'}',
    ].join(' ');
  }

  /// One line per event, for plain-text use.
  static List<String> generateLifecycleEvents({
    required FinancialItem holding,
    required List<SipPlan> sips,
    required List<SipSchedulePeriod> schedulePeriods,
    List<SwpPlan> swps = const [],
    List<SwpSchedulePeriod> swpPeriods = const [],
    required List<Transaction> transactions,
  }) =>
      buildTimeline(
        holding: holding,
        sips: sips,
        schedulePeriods: schedulePeriods,
        swps: swps,
        swpPeriods: swpPeriods,
        transactions: transactions,
      ).map((e) => e.headline).toList();

  static String generateSummary({
    required FinancialItem holding,
    required List<SipPlan> sips,
    required List<SipSchedulePeriod> schedulePeriods,
    required List<Transaction> transactions,
  }) =>
      generateLifecycleEvents(
        holding: holding,
        sips: sips,
        schedulePeriods: schedulePeriods,
        transactions: transactions,
      ).join('\n');
}
