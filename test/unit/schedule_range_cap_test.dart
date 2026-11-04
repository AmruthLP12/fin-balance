import 'package:finbalance/core/scheduling/investment_schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('daily schedule with only an end date is not truncated at 360 dates', () {
    final dates = InvestmentScheduleService.generateScheduleDatesRange(
      startDate: DateTime.utc(2024, 1, 1),
      endDate: DateTime.utc(2025, 12, 31),
      frequency: ScheduleFrequency.daily,
    );
    expect(dates.length, 731); // 2024 is a leap year
    expect(dates.last, DateTime.utc(2025, 12, 31));
  });
}
