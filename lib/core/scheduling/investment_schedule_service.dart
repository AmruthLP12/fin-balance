import 'recurring_date_calculator.dart';

/// Supported investment frequencies for recurring and one-time contributions.
enum ScheduleFrequency {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  oneTime('One-time'),
  quarterly('Quarterly'),
  yearly('Yearly');

  final String label;
  const ScheduleFrequency(this.label);

  static ScheduleFrequency fromString(String? val) {
    if (val == null) return ScheduleFrequency.monthly;
    final normalized =
        val.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    for (final freq in ScheduleFrequency.values) {
      if (freq.name.toLowerCase() == normalized ||
          freq.name.toLowerCase() == val.toLowerCase()) {
        return freq;
      }
    }
    if (normalized == 'onetime' || normalized == 'one_time') {
      return ScheduleFrequency.oneTime;
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
}
