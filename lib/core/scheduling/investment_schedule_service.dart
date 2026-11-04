import 'recurring_date_calculator.dart';

/// Supported investment and withdrawal frequencies for recurring schedules and one-time contributions.
enum ScheduleFrequency {
  oneTime('One Time'),
  daily('Daily'),
  weekly('Weekly'),
  fortnightly('Fortnightly'),
  monthly('Monthly'),
  quarterly('Quarterly'),
  halfYearly('Half-Yearly'),
  yearly('Yearly');

  final String label;
  const ScheduleFrequency(this.label);

  static ScheduleFrequency fromString(String? val) {
    if (val == null) return ScheduleFrequency.monthly;
    final normalized =
        val.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    for (final freq in ScheduleFrequency.values) {
      if (freq.name.toLowerCase() == normalized ||
          freq.name.toLowerCase() == val.toLowerCase() ||
          freq.label.toLowerCase() == val.toLowerCase()) {
        return freq;
      }
    }
    if (normalized == 'onetime' || normalized == 'one_time') {
      return ScheduleFrequency.oneTime;
    }
    if (normalized == 'biweekly' ||
        normalized == 'bi_weekly' ||
        normalized == 'fortnightly' ||
        normalized == 'two_weeks') {
      return ScheduleFrequency.fortnightly;
    }
    if (normalized == 'halfyearly' ||
        normalized == 'half_yearly' ||
        normalized == 'semiannual' ||
        normalized == 'semi_annual') {
      return ScheduleFrequency.halfYearly;
    }
    return ScheduleFrequency.monthly;
  }
}

/// A single generated schedule occurrence.
class ScheduleOccurrence {
  final int installmentNumber;
  final DateTime scheduledDate;
  final bool isPast;
  final bool isFuture;

  const ScheduleOccurrence({
    required this.installmentNumber,
    required this.scheduledDate,
    required this.isPast,
    required this.isFuture,
  });

  @override
  String toString() =>
      'Occurrence #$installmentNumber on ${scheduledDate.toIso8601String().split('T').first} (isPast: $isPast)';
}

/// Comprehensive summary of a generated investment schedule.
class ScheduleSummary {
  final int totalInstallments;
  final int pastInstallments;
  final int futureInstallments;
  final int amountPerInstallmentPaise;
  final int totalScheduledAmountPaise;
  final int pastScheduledAmountPaise;
  final int futureScheduledAmountPaise;
  final List<ScheduleOccurrence> occurrences;

  const ScheduleSummary({
    required this.totalInstallments,
    required this.pastInstallments,
    required this.futureInstallments,
    required this.amountPerInstallmentPaise,
    required this.totalScheduledAmountPaise,
    required this.pastScheduledAmountPaise,
    required this.futureScheduledAmountPaise,
    required this.occurrences,
  });

  List<ScheduleOccurrence> get pastOccurrences =>
      occurrences.where((o) => o.isPast).toList();

  List<ScheduleOccurrence> get futureOccurrences =>
      occurrences.where((o) => o.isFuture).toList();

  int get pastInvestedAmountPaise => pastScheduledAmountPaise;
}

/// High-reliability service for generating and calculating investment schedules.
///
/// Guarantees:
/// 1. Exact installment count generated without off-by-one errors.
/// 2. Month-end clamping without progressive date drift (e.g. 31st -> Feb 28/29 -> Mar 31).
/// 3. Day of week consistency for weekly schedules.
/// 4. Dynamic past vs future partition based on device local date.
/// 5. Absolute separation of past confirmed amounts from future planned contributions.
class InvestmentScheduleService {
  const InvestmentScheduleService._();

  /// Normalize a [DateTime] to calendar date at UTC midnight for stable comparison.
  static DateTime toUtcDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Alias for [calculateSchedule] supporting [totalInstallments] parameter name.
  static ScheduleSummary generateSchedule({
    required DateTime startDate,
    required int totalInstallments,
    required ScheduleFrequency frequency,
    required int amountPerInstallmentPaise,
    DateTime? asOfDate,
  }) {
    return calculateSchedule(
      startDate: startDate,
      installmentCount: totalInstallments,
      frequency: frequency,
      amountPerInstallmentPaise: amountPerInstallmentPaise,
      asOfDate: asOfDate,
    );
  }

  /// Calculates the investment schedule summary and individual occurrences.
  ///
  /// [asOfDate] defaults to today's local date. Dates on or before today are past;
  /// dates strictly after today are future.
  static ScheduleSummary calculateSchedule({
    required DateTime startDate,
    required int installmentCount,
    required ScheduleFrequency frequency,
    required int amountPerInstallmentPaise,
    DateTime? asOfDate,
  }) {
    final effectiveCount = frequency == ScheduleFrequency.oneTime
        ? 1
        : (installmentCount <= 0 ? 0 : installmentCount);

    if (effectiveCount <= 0) {
      return ScheduleSummary(
        totalInstallments: 0,
        pastInstallments: 0,
        futureInstallments: 0,
        amountPerInstallmentPaise: amountPerInstallmentPaise,
        totalScheduledAmountPaise: 0,
        pastScheduledAmountPaise: 0,
        futureScheduledAmountPaise: 0,
        occurrences: const [],
      );
    }

    final todayDate = toUtcDate(asOfDate ?? DateTime.now());
    final rawDates = generateScheduleDates(
      startDate: startDate,
      installmentCount: effectiveCount,
      frequency: frequency,
    );

    final occurrences = <ScheduleOccurrence>[];
    int pastCount = 0;
    int futureCount = 0;

    for (int i = 0; i < rawDates.length; i++) {
      final date = rawDates[i];
      // Scheduled dates on or before today are classified as past
      final isPast = !date.isAfter(todayDate);
      final isFuture = !isPast;

      if (isPast) {
        pastCount++;
      } else {
        futureCount++;
      }

      occurrences.add(ScheduleOccurrence(
        installmentNumber: i + 1,
        scheduledDate: date,
        isPast: isPast,
        isFuture: isFuture,
      ));
    }

    return ScheduleSummary(
      totalInstallments: effectiveCount,
      pastInstallments: pastCount,
      futureInstallments: futureCount,
      amountPerInstallmentPaise: amountPerInstallmentPaise,
      totalScheduledAmountPaise: amountPerInstallmentPaise * effectiveCount,
      pastScheduledAmountPaise: amountPerInstallmentPaise * pastCount,
      futureScheduledAmountPaise: amountPerInstallmentPaise * futureCount,
      occurrences: occurrences,
    );
  }

  /// The [i]th occurrence (0-based) of a schedule starting at [start] (UTC date).
  /// Month-based frequencies always derive from the original day, so there is no drift.
  static DateTime _occurrenceAt(
      DateTime start, ScheduleFrequency frequency, int i) {
    final stepMonths = switch (frequency) {
      ScheduleFrequency.monthly => 1,
      ScheduleFrequency.quarterly => 3,
      ScheduleFrequency.halfYearly => 6,
      ScheduleFrequency.yearly => 12,
      _ => 0,
    };
    if (stepMonths > 0) {
      final totalMonths = start.year * 12 + (start.month - 1) + i * stepMonths;
      return RecurringDateCalculator.calculateOccurrenceDate(
          totalMonths ~/ 12, (totalMonths % 12) + 1, start.day);
    }
    final stepDays = switch (frequency) {
      ScheduleFrequency.daily => 1,
      ScheduleFrequency.weekly => 7,
      ScheduleFrequency.fortnightly => 14,
      _ => 0, // oneTime
    };
    return DateTime.utc(start.year, start.month, start.day + i * stepDays);
  }

  /// Generates the exact sequence of calendar dates for the given configuration.
  static List<DateTime> generateScheduleDates({
    required DateTime startDate,
    required int installmentCount,
    required ScheduleFrequency frequency,
  }) {
    if (installmentCount <= 0) return const [];

    final start = toUtcDate(startDate);
    if (frequency == ScheduleFrequency.oneTime) return [start];

    return [
      for (int i = 0; i < installmentCount; i++)
        _occurrenceAt(start, frequency, i),
    ];
  }

  /// Generates dates for a schedule given start date, optional end date, and optional installment count.
  /// If [installmentCount] is specified, generates up to [installmentCount] occurrences
  /// (also bounded by [endDate] when given).
  /// If only [endDate] is specified, generates every occurrence up to and including it.
  /// If neither is specified, defaults to 12 occurrences (or 1 for One Time).
  static List<DateTime> generateScheduleDatesRange({
    required DateTime startDate,
    DateTime? endDate,
    int? installmentCount,
    required ScheduleFrequency frequency,
  }) {
    final start = toUtcDate(startDate);
    if (frequency == ScheduleFrequency.oneTime) return [start];

    final end = endDate != null ? toUtcDate(endDate) : null;
    final hasCount = installmentCount != null && installmentCount > 0;
    final maxCount = hasCount ? installmentCount : (end != null ? null : 12);

    final dates = <DateTime>[];
    for (int i = 0; maxCount == null || i < maxCount; i++) {
      final date = _occurrenceAt(start, frequency, i);
      if (end != null && date.isAfter(end)) break;
      dates.add(date);
      // ponytail: hard ceiling guards a runaway loop; raise if >100k installments is ever valid
      if (i >= 100000) break;
    }
    return dates;
  }
}
