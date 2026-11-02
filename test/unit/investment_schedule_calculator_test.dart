import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/core/scheduling/investment_schedule_service.dart';

void main() {
  group('InvestmentScheduleService - Schedule Generation & Rules', () {
    test('One-time investment generates exactly 1 occurrence on start date',
        () {
      final start = DateTime.utc(2026, 3, 15);
      final dates = InvestmentScheduleService.generateScheduleDates(
        startDate: start,
        installmentCount: 1,
        frequency: ScheduleFrequency.oneTime,
      );

      expect(dates.length, equals(1));
      expect(dates.first, equals(start));

      // Even if installmentCount > 1, oneTime must enforce count = 1
      final calc = InvestmentScheduleService.calculateSchedule(
        startDate: start,
        installmentCount: 24,
        frequency: ScheduleFrequency.oneTime,
        amountPerInstallmentPaise: 50000,
      );
      expect(calc.totalInstallments, equals(1));
      expect(calc.totalScheduledAmountPaise, equals(50000));
    });

    test('Daily schedule generates one occurrence per day', () {
      final start = DateTime.utc(2026, 2, 27);
      final dates = InvestmentScheduleService.generateScheduleDates(
        startDate: start,
        installmentCount: 5,
        frequency: ScheduleFrequency.daily,
      );

      expect(dates.length, equals(5));
      expect(dates[0], equals(DateTime.utc(2026, 2, 27)));
      expect(dates[1], equals(DateTime.utc(2026, 2, 28)));
      expect(
          dates[2],
          equals(
              DateTime.utc(2026, 3, 1))); // Non-leap year 2026 moves to March
      expect(dates[3], equals(DateTime.utc(2026, 3, 2)));
      expect(dates[4], equals(DateTime.utc(2026, 3, 3)));
    });

    test(
        'Weekly schedule generates occurrence every 7 days maintaining weekday',
        () {
      final start = DateTime.utc(2026, 1, 5); // Monday
      expect(start.weekday, equals(DateTime.monday));

      final dates = InvestmentScheduleService.generateScheduleDates(
        startDate: start,
        installmentCount: 4,
        frequency: ScheduleFrequency.weekly,
      );

      expect(dates.length, equals(4));
      for (final date in dates) {
        expect(date.weekday, equals(DateTime.monday));
      }
      expect(dates[0], equals(DateTime.utc(2026, 1, 5)));
      expect(dates[1], equals(DateTime.utc(2026, 1, 12)));
      expect(dates[2], equals(DateTime.utc(2026, 1, 19)));
      expect(dates[3], equals(DateTime.utc(2026, 1, 26)));
    });

    test(
        'Monthly schedule starting on 31st clamps properly without cumulative drift',
        () {
      // 2024 is a leap year (Feb has 29 days)
      final start = DateTime.utc(2024, 1, 31);
      final dates = InvestmentScheduleService.generateScheduleDates(
        startDate: start,
        installmentCount: 5,
        frequency: ScheduleFrequency.monthly,
      );

      expect(dates.length, equals(5));
      expect(dates[0], equals(DateTime.utc(2024, 1, 31)));
      expect(dates[1], equals(DateTime.utc(2024, 2, 29))); // Leap Feb: 29
      expect(dates[2], equals(DateTime.utc(2024, 3, 31))); // Returns to 31!
      expect(dates[3], equals(DateTime.utc(2024, 4, 30))); // 30 days
      expect(dates[4], equals(DateTime.utc(2024, 5, 31))); // Returns to 31!
    });

    test('Handles zero and negative installments gracefully', () {
      final start = DateTime.utc(2026, 1, 1);
      final calc = InvestmentScheduleService.calculateSchedule(
        startDate: start,
        installmentCount: 0,
        frequency: ScheduleFrequency.monthly,
        amountPerInstallmentPaise: 50000,
      );

      expect(calc.totalInstallments, equals(0));
      expect(calc.pastInstallments, equals(0));
      expect(calc.futureInstallments, equals(0));
      expect(calc.totalScheduledAmountPaise, equals(0));
      expect(calc.occurrences, isEmpty);
    });
  });

  group('InvestmentScheduleService - Past vs Future Partitioning', () {
    test('Example 1 - Historical only investment', () {
      // Scheme: SBI Small Cap Fund, ₹100, 01 Jan 2024, Monthly, 12 installments
      // As of 2026: all in past
      final asOfDate = DateTime.utc(2026, 11, 2);
      final calc = InvestmentScheduleService.calculateSchedule(
        startDate: DateTime.utc(2024, 1, 1),
        installmentCount: 12,
        frequency: ScheduleFrequency.monthly,
        amountPerInstallmentPaise: 10000, // ₹100 in paise
        asOfDate: asOfDate,
      );

      expect(calc.totalInstallments, equals(12));
      expect(calc.pastInstallments, equals(12));
      expect(calc.futureInstallments, equals(0));
      expect(calc.pastScheduledAmountPaise, equals(120000)); // ₹1,200
      expect(calc.futureScheduledAmountPaise, equals(0));
      expect(calc.totalScheduledAmountPaise, equals(120000));
    });

    test('Example 2 - Mixed past and future investment', () {
      // 01 Jan 2026, ₹500, Monthly, 24 installments.
      // As of 02 Nov 2026:
      // Installments on 1st of each month:
      // Jan 1 to Nov 1 = 11 past installments
      // Dec 1 2026 to Dec 1 2027 = 13 future installments
      final asOfDate = DateTime.utc(2026, 11, 2);
      final calc = InvestmentScheduleService.calculateSchedule(
        startDate: DateTime.utc(2026, 1, 1),
        installmentCount: 24,
        frequency: ScheduleFrequency.monthly,
        amountPerInstallmentPaise: 50000, // ₹500 in paise
        asOfDate: asOfDate,
      );

      expect(calc.totalInstallments, equals(24));
      expect(calc.pastInstallments, equals(11));
      expect(calc.futureInstallments, equals(13));
      expect(calc.pastScheduledAmountPaise, equals(550000)); // ₹5,500
      expect(calc.futureScheduledAmountPaise, equals(650000)); // ₹6,500
      expect(calc.totalScheduledAmountPaise, equals(1200000)); // ₹12,000
    });

    test('Example 3 - Future only investment', () {
      // Future start date: 01 Jan 2027
      // As of 02 Nov 2026: all 12 are in future
      final asOfDate = DateTime.utc(2026, 11, 2);
      final calc = InvestmentScheduleService.calculateSchedule(
        startDate: DateTime.utc(2027, 1, 1),
        installmentCount: 12,
        frequency: ScheduleFrequency.monthly,
        amountPerInstallmentPaise: 100000, // ₹1,000 in paise
        asOfDate: asOfDate,
      );

      expect(calc.totalInstallments, equals(12));
      expect(calc.pastInstallments, equals(0));
      expect(calc.futureInstallments, equals(12));
      expect(calc.pastScheduledAmountPaise, equals(0)); // ₹0 invested
      expect(
          calc.futureScheduledAmountPaise, equals(1200000)); // ₹12,000 planned
      expect(calc.totalScheduledAmountPaise, equals(1200000));
    });

    test('Scheduled installment on current date is treated as past/today', () {
      final today = DateTime.utc(2026, 11, 2);
      final calc = InvestmentScheduleService.calculateSchedule(
        startDate: today,
        installmentCount: 3,
        frequency: ScheduleFrequency.daily,
        amountPerInstallmentPaise: 10000,
        asOfDate: today,
      );

      // Today (Nov 2) -> past
      // Tomorrow (Nov 3) -> future
      // Day after (Nov 4) -> future
      expect(calc.pastInstallments, equals(1));
      expect(calc.futureInstallments, equals(2));
      expect(calc.occurrences[0].isPast, isTrue);
      expect(calc.occurrences[1].isFuture, isTrue);
      expect(calc.occurrences[2].isFuture, isTrue);
    });
  });
}
