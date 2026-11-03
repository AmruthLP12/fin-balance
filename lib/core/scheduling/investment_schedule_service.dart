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

  /// Generates the exact sequence of calendar dates for the given configuration.
  static List<DateTime> generateScheduleDates({
    required DateTime startDate,
    required int installmentCount,
    required ScheduleFrequency frequency,
  }) {
    if (installmentCount <= 0) return const [];

    final normalizedStart = toUtcDate(startDate);
    if (frequency == ScheduleFrequency.oneTime) {
      return [normalizedStart];
    }

    final dates = <DateTime>[];

    switch (frequency) {
      case ScheduleFrequency.daily:
        for (int i = 0; i < installmentCount; i++) {
          dates.add(DateTime.utc(
            normalizedStart.year,
            normalizedStart.month,
            normalizedStart.day + i,
          ));
        }
        break;

      case ScheduleFrequency.weekly:
        for (int i = 0; i < installmentCount; i++) {
          dates.add(DateTime.utc(
            normalizedStart.year,
            normalizedStart.month,
            normalizedStart.day + (i * 7),
          ));
        }
        break;

      case ScheduleFrequency.fortnightly:
        for (int i = 0; i < installmentCount; i++) {
          dates.add(DateTime.utc(
            normalizedStart.year,
            normalizedStart.month,
            normalizedStart.day + (i * 14),
          ));
        }
        break;

      case ScheduleFrequency.monthly:
        final originalDay = normalizedStart.day;
        for (int i = 0; i < installmentCount; i++) {
          final totalMonths =
              (normalizedStart.year * 12 + (normalizedStart.month - 1)) + i;
          final targetYear = totalMonths ~/ 12;
          final targetMonth = (totalMonths % 12) + 1;
          dates.add(RecurringDateCalculator.calculateOccurrenceDate(
            targetYear,
            targetMonth,
            originalDay,
          ));
        }
        break;

      case ScheduleFrequency.quarterly:
        final originalDay = normalizedStart.day;
        for (int i = 0; i < installmentCount; i++) {
          final totalMonths =
              (normalizedStart.year * 12 + (normalizedStart.month - 1)) +
                  (i * 3);
          final targetYear = totalMonths ~/ 12;
          final targetMonth = (totalMonths % 12) + 1;
          dates.add(RecurringDateCalculator.calculateOccurrenceDate(
            targetYear,
            targetMonth,
            originalDay,
          ));
        }
        break;

      case ScheduleFrequency.halfYearly:
        final originalDay = normalizedStart.day;
        for (int i = 0; i < installmentCount; i++) {
          final totalMonths =
              (normalizedStart.year * 12 + (normalizedStart.month - 1)) +
                  (i * 6);
          final targetYear = totalMonths ~/ 12;
          final targetMonth = (totalMonths % 12) + 1;
          dates.add(RecurringDateCalculator.calculateOccurrenceDate(
            targetYear,
            targetMonth,
            originalDay,
          ));
        }
        break;

      case ScheduleFrequency.yearly:
        final originalDay = normalizedStart.day;
        final originalMonth = normalizedStart.month;
        for (int i = 0; i < installmentCount; i++) {
          final targetYear = normalizedStart.year + i;
          dates.add(RecurringDateCalculator.calculateOccurrenceDate(
            targetYear,
            originalMonth,
            originalDay,
          ));
        }
        break;

      case ScheduleFrequency.oneTime:
        dates.add(normalizedStart);
        break;
    }

    return dates;
  }

  /// Generates dates for a schedule given start date, optional end date, and optional installment count.
  /// If [installmentCount] is specified, generates up to [installmentCount] occurrences.
  /// If [endDate] is specified, generates occurrences not exceeding [endDate].
  /// If neither is specified, defaults to 12 occurrences (or 1 for One Time).
  static List<DateTime> generateScheduleDatesRange({
    required DateTime startDate,
    DateTime? endDate,
    int? installmentCount,
    required ScheduleFrequency frequency,
  }) {
    final normalizedStart = toUtcDate(startDate);
    if (frequency == ScheduleFrequency.oneTime) {
      return [normalizedStart];
    }

    final normalizedEnd = endDate != null ? toUtcDate(endDate) : null;
    final maxCount = installmentCount != null && installmentCount > 0
        ? installmentCount
        : (normalizedEnd != null ? 360 : 12);

    final generated = generateScheduleDates(
      startDate: normalizedStart,
      installmentCount: maxCount,
      frequency: frequency,
    );

    if (normalizedEnd != null) {
      return generated.where((d) => !d.isAfter(normalizedEnd)).toList();
    }
    return generated;
  }
}
