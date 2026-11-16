import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/data/loan/emi_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/features/liabilities/loan_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EMI and tenure are inverse of each other', () {
    final emi = LoanCalculator.emiFor(100000000, 8.5, 240); // ₹10L, 20y
    expect(emi, closeTo(867823, 100)); // ~₹8,678
    expect(LoanCalculator.tenureMonthsFor(100000000, 8.5, emi), 240);
    expect(LoanCalculator.emiFor(120000, 0, 12), 10000);
    expect(LoanCalculator.tenureMonthsFor(100000000, 12, 100), isNull);
  });

  test('auto EMI posts once per due date and skips other borrowings', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    Future<int> add(String sub) =>
        db.into(db.financialItems).insert(FinancialItemsCompanion(
              profileId: const drift.Value(1),
              name: drift.Value(sub),
              itemType: const drift.Value('liability'),
              subType: drift.Value(sub),
              categoryId: const drift.Value(1),
              currentValuationPaise: const drift.Value(1000000),
              initialValuePaise: const drift.Value(1000000),
              emiPaise: const drift.Value(100000),
              startDate: drift.Value(DateTime(2026, 1, 31)),
              tenureYears: const drift.Value(5),
              createdAt: drift.Value(DateTime(2026, 1, 1)),
            ));
    final home = await add('home_loan');
    final other = await add('other_liability');

    // Due: 28 Feb, 31 Mar (month-end clamped).
    expect(await applyDueEmis(db, today: DateTime(2026, 3, 31)), 2);
    expect(await applyDueEmis(db, today: DateTime(2026, 3, 31)), 0);
    expect(
        (await db.financialItemsDao.getItemById(home))!.currentValuationPaise,
        800000);
    expect(
        (await db.financialItemsDao.getItemById(other))!.currentValuationPaise,
        1000000);
  });
}
