import 'package:drift/native.dart';
import 'package:finbalance/core/cash_flow.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/data/assets/recurring_deposit_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/features/assets/screens/deposit_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> openForm(WidgetTester tester, {required bool recurring}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => DepositFormScreen(recurring: recurring),
                ),
              ),
              child: const Text('Open form'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
  }

  testWidgets('FD saves a linked investment outflow and deposit details',
      (tester) async {
    await openForm(tester, recurring: false);
    expect(find.text('Account number'), findsNothing);
    await tester.enterText(find.byType(TextFormField).at(0), '10000');
    await tester.enterText(find.byType(TextFormField).at(1), '7.5');
    await tester.enterText(find.byType(TextFormField).at(3), 'Example Bank');
    await tester.tap(find.byTooltip('Save deposit'));
    await tester.pumpAndSettle();

    final items = await db.financialItemsDao.getItemsByProfile(1);
    final fd = items.singleWhere((item) => item.subType == 'fixed_deposit');
    expect(fd.initialValuePaise, 1000000);
    expect(fd.bankName, 'Example Bank');
    expect(fd.interestRateBasisPoints, 750);
    expect(fd.depositCompoundingMonths, 3);
    expect(fd.depositCumulative, isTrue);
    expect(fd.depositTaxSaving, isFalse);

    final transactions =
        await db.transactionsDao.getTransactionsByItem(1, fd.id);
    expect(transactions, hasLength(1));
    expect(transactions.single.transactionType, 'investment_purchase');
    expect(flowOf(transactions.single.transactionType), MoneyFlow.investment);
  });

  testWidgets('RD saves a monthly schedule and posts its first due payment',
      (tester) async {
    await openForm(tester, recurring: true);
    expect(find.text('Cumulative Deposit'), findsNothing);
    expect(find.text('Tax saving u/s 80C'), findsNothing);
    await tester.enterText(find.byType(TextFormField).at(0), '1000');
    await tester.enterText(find.byType(TextFormField).at(1), '6.5');
    await tester.tap(find.byTooltip('Save deposit'));
    await tester.pumpAndSettle();

    final items = await db.financialItemsDao.getItemsByProfile(1);
    final rd = items.singleWhere((item) => item.subType == 'recurring_deposit');
    expect(rd.initialValuePaise, 100000);
    expect(rd.currentValuationPaise, 100000);
    final schedules =
        await db.recurringTransactionsDao.getSchedulesByItem(1, rd.id);
    expect(schedules, hasLength(1));
    expect(schedules.single.frequency, 'monthly');
    final transactions =
        await db.transactionsDao.getTransactionsByItem(1, rd.id);
    expect(transactions, hasLength(1));
    expect(transactions.single.source, recurringDepositAutoPostSource);
    expect(flowOf(transactions.single.transactionType), MoneyFlow.investment);
  });

  testWidgets('non-cumulative FD schedules interest payouts', (tester) async {
    await openForm(tester, recurring: false);
    await tester.enterText(find.byType(TextFormField).at(0), '10000');
    await tester.enterText(find.byType(TextFormField).at(1), '7.5');
    await tester.ensureVisible(find.text('Cumulative Deposit'));
    await tester.tap(find.text('Cumulative Deposit'));
    await tester.tap(find.byTooltip('Save deposit'));
    await tester.pumpAndSettle();

    final items = await db.financialItemsDao.getItemsByProfile(1);
    final fd = items.singleWhere((item) => item.subType == 'fixed_deposit');
    expect(fd.depositCumulative, isFalse);
    final schedules =
        await db.recurringTransactionsDao.getSchedulesByItem(1, fd.id);
    expect(schedules, hasLength(1));
    expect(schedules.single.recurringType, fixedDepositInterestType);
  });
}
