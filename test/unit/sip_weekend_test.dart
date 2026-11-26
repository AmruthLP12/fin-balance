import 'package:finbalance/core/scheduling/investment_schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Saturday and Sunday SIP dates move to Monday', () {
    // 3 Jan 2026 is a Saturday, 4 Jan a Sunday, 5 Jan a Monday.
    expect(InvestmentScheduleService.nextWeekday(DateTime.utc(2026, 1, 3)),
        DateTime.utc(2026, 1, 5));
    expect(InvestmentScheduleService.nextWeekday(DateTime.utc(2026, 1, 4)),
        DateTime.utc(2026, 1, 5));
    expect(InvestmentScheduleService.nextWeekday(DateTime.utc(2026, 1, 5)),
        DateTime.utc(2026, 1, 5));
  });

  test('monthly schedule keeps weekdays and shifts weekends only when asked',
      () {
    final plain = InvestmentScheduleService.generateScheduleDates(
        startDate: DateTime(2026, 1, 3),
        installmentCount: 3,
        frequency: ScheduleFrequency.monthly);
    expect(plain.first, DateTime.utc(2026, 1, 3));
    final shifted = InvestmentScheduleService.generateScheduleDates(
        startDate: DateTime(2026, 1, 3),
        installmentCount: 3,
        frequency: ScheduleFrequency.monthly,
        weekendToMonday: true);
    // Jan 3 Sat -> Jan 5, Feb 3 Tue stays, Mar 3 Tue stays.
    expect(shifted, [
      DateTime.utc(2026, 1, 5),
      DateTime.utc(2026, 2, 3),
      DateTime.utc(2026, 3, 3),
    ]);
  });
}
