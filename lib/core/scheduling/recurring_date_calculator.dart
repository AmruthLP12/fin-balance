import 'dart:math';

/// High-reliability calculator for recurring monthly, quarterly, and custom investment dates.
/// Enforces precise month-end clamping (e.g. 31st clamps to 28th/29th Feb, 30th Apr)
/// while guaranteeing zero date drift across consecutive months.
class RecurringDateCalculator {
  const RecurringDateCalculator._();

  /// Returns the maximum number of valid calendar days in the given [year] and [month].
  ///
  /// Examples:
  /// - Feb 2024 (Leap year): 29 days
  /// - Feb 2025 (Standard year): 28 days
  /// - Apr, Jun, Sep, Nov: 30 days
  /// - Jan, Mar, May, Jul, Aug, Oct, Dec: 31 days
  static int daysInMonth(int year, int month) {
    return DateTime.utc(year, month + 1, 0).day;
  }

  /// Clamps the [configuredDay] (1-31) to the maximum valid day for the given [year] and [month].
  static int clampDay(int year, int month, int configuredDay) {
    final maxDays = daysInMonth(year, month);
    return min(max(1, configuredDay), maxDays);
  }

  /// Calculates the exact calendar date for a recurring deduction,
  /// always calculating from the original [configuredDay] to prevent date drift.
  static DateTime calculateOccurrenceDate(
      int year, int month, int configuredDay) {
    final clampedDay = clampDay(year, month, configuredDay);
    return DateTime.utc(year, month, clampedDay);
  }

  /// Generates all monthly occurrence dates between [fromDate] and [toDate] (inclusive)
  /// for the specified [configuredDay].
  ///
  /// Example:
  /// configuredDay: 31, from: Jan 2024, to: May 2024
  /// Output: [2024-01-31, 2024-02-29, 2024-03-31, 2024-04-30, 2024-05-31]
  static List<DateTime> generateMonthlyOccurrences({
    required DateTime fromDate,
    required DateTime toDate,
    required int configuredDay,
  }) {
    if (fromDate.isAfter(toDate)) return [];

    final occurrences = <DateTime>[];
    int currentYear = fromDate.year;
    int currentMonth = fromDate.month;

    final targetEndYear = toDate.year;
    final targetEndMonth = toDate.month;

    while (currentYear < targetEndYear ||
        (currentYear == targetEndYear && currentMonth <= targetEndMonth)) {
      final occurrence =
          calculateOccurrenceDate(currentYear, currentMonth, configuredDay);

      // Verify occurrence falls within the bounds
      final isAfterOrEqualFrom = !occurrence
          .isBefore(DateTime.utc(fromDate.year, fromDate.month, fromDate.day));
      final isBeforeOrEqualTo = !occurrence
          .isAfter(DateTime.utc(toDate.year, toDate.month, toDate.day));

      if (isAfterOrEqualFrom && isBeforeOrEqualTo) {
        occurrences.add(occurrence);
      }

      // Advance to next calendar month
      currentMonth++;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }
    }

    return occurrences;
  }
}
