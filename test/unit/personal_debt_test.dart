import 'package:drift/native.dart';
import 'package:finbalance/core/cash_flow.dart';
import 'package:finbalance/core/constants/asset_categories.dart';
import 'package:finbalance/core/formatting/currency_formatter.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/features/personal_debt/personal_debt_details_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('money lent: interest-only payments keep the principal, return closes',
      () async {
    final id = await db.transactionsDao.openPersonalDebt(
        profileId: 1,
        lent: true,
        person: 'Ravi',
        amountPaise: 500000,
        date: DateTime(2026, 1, 1),
        rateBasisPoints: 200,
        ratePeriod: 'monthly');
    var item = (await db.financialItemsDao.getItemById(id))!;
    expect(item.itemType, 'asset');
    expect(item.subType, 'money_lent');
    expect(personalMonthlyInterest(item), 10000); // 2% of 5,000
    expect(personalRateLabel(item), '2% per month');

    await db.transactionsDao.recordPersonalEntry(
        itemId: id,
        interest: true,
        amountPaise: 10000,
        date: DateTime(2026, 2, 1));
    item = (await db.financialItemsDao.getItemById(id))!;
    expect(item.currentValuationPaise, 500000);

    await db.transactionsDao.recordPersonalEntry(
        itemId: id,
        interest: false,
        amountPaise: 200000,
        date: DateTime(2026, 3, 1));
    item = (await db.financialItemsDao.getItemById(id))!;
    expect(item.currentValuationPaise, 300000);
    expect(personalMonthlyInterest(item), 6000); // on the remaining amount

    await db.transactionsDao.recordPersonalEntry(
        itemId: id,
        interest: false,
        amountPaise: 999999,
        date: DateTime(2026, 4, 1));
    item = (await db.financialItemsDao.getItemById(id))!;
    expect(item.currentValuationPaise, 0);
    expect(item.status, 'closed');

    final types = (await db.select(db.transactions).get())
        .map((t) => t.transactionType)
        .toList();
    expect(types,
        ['lend_given', 'interest_received', 'lend_repaid', 'lend_repaid']);
    expect(types.map(flowOf), [
      MoneyFlow.investment,
      MoneyFlow.income,
      MoneyFlow.income,
      MoneyFlow.income,
    ]);
  });

  test('borrowing: plain record, repayments are expenses', () async {
    final id = await db.transactionsDao.openPersonalDebt(
        profileId: 1,
        lent: false,
        person: 'Friend',
        amountPaise: 450000,
        date: DateTime(2026, 1, 1));
    final item = (await db.financialItemsDao.getItemById(id))!;
    expect(item.subType, 'other_liability');
    expect(personalMonthlyInterest(item), isNull);
    await db.transactionsDao.recordPersonalEntry(
        itemId: id,
        interest: true,
        amountPaise: 5000,
        date: DateTime(2026, 2, 1));
    expect(flowOf('interest_paid'), MoneyFlow.expense);
    expect(flowOf('borrowing_received'), MoneyFlow.income);
    expect(flowOf('debt_repayment'), MoneyFlow.expense);
  });

  test('lent and borrowed records keep interest due date and amount', () async {
    final dueDate = DateTime(2026, 12, 5);
    final lentId = await db.transactionsDao.openPersonalDebt(
        profileId: 1,
        lent: true,
        person: 'Ravi',
        amountPaise: 500000,
        date: DateTime(2026, 1, 1),
        rateBasisPoints: 200,
        ratePeriod: 'monthly',
        interestDueDate: dueDate,
        interestDueAmountPaise: 10000);
    final lent = (await db.financialItemsDao.getItemById(lentId))!;
    expect(lent.interestDueDate, dueDate);
    expect(lent.interestDueAmountPaise, 10000);

    final borrowedId = await db.transactionsDao.openPersonalDebt(
        profileId: 1,
        lent: false,
        person: 'Friend',
        amountPaise: 450000,
        date: DateTime(2026, 1, 1),
        interestDueDate: dueDate,
        interestDueAmountPaise: 5000);
    final borrowed = (await db.financialItemsDao.getItemById(borrowedId))!;
    expect(borrowed.interestDueDate, dueDate);
    expect(borrowed.interestDueAmountPaise, 5000);
  });

  test('K / L / Cr amounts and groups', () {
    String f(num rupees) =>
        CurrencyFormatter.formatPaiseCompact((rupees * 100).round());
    expect(f(9999), '₹9,999.00');
    expect(f(10000), '₹10K');
    expect(f(12500), '₹12.5K');
    expect(f(150000), '₹1.5L');
    expect(f(25000000), '₹2.5Cr');
    expect(assetGroups.any((g) => g.value == 'pli'), isFalse);
    expect(assetGroups.any((g) => g.value == 'money_lent'), isTrue);
  });
}
