import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../../features/liabilities/loan_calculator.dart';

const autoEmiSource = 'auto_emi';

/// Posts every EMI that has fallen due since the last run, once per due date
/// (counted by the 'auto_emi' transactions already on the loan).
Future<int> applyDueEmis(AppDatabase db, {DateTime? today}) async {
  final now = today ?? DateTime.now();
  final day = DateTime(now.year, now.month, now.day);
  final loans = await (db.select(db.financialItems)
        ..where((t) => t.itemType.equals('liability')))
      .get();
  var posted = 0;
  for (final loan in loans.where(LoanCalculator.autoDeducts)) {
    final done = await (db.select(db.transactions)
          ..where((t) =>
              t.financialItemId.equals(loan.id) &
              t.source.equals(autoEmiSource)))
        .get();
    var balance = loan.currentValuationPaise;
    for (final due in LoanCalculator.emiDueDates(loan, day).skip(done.length)) {
      if (balance <= 0) break;
      final amount = balance < loan.emiPaise! ? balance : loan.emiPaise!;
      await db.transactionsDao.recordDebtRepayment(
        profileId: loan.profileId,
        financialItemId: loan.id,
        categoryId: loan.categoryId,
        transactionDate: due,
        amountPaise: amount,
        notes: 'Auto EMI',
        source: autoEmiSource,
      );
      balance -= amount;
      posted++;
    }
  }
  return posted;
}
