import 'package:drift/native.dart';
import 'package:finbalance/core/cash_flow.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/data/assets/recurring_deposit_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/features/assets/screens/deposit_details_screen.dart';
import 'package:finbalance/features/assets/screens/deposit_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> openForm(
    WidgetTester tester, {
    required bool recurring,
    FinancialItem? holding,
  }) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => DepositFormScreen(
                    recurring: recurring,
                    holding: holding,
                  ),
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
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
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
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
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
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final items = await db.financialItemsDao.getItemsByProfile(1);
    final fd = items.singleWhere((item) => item.subType == 'fixed_deposit');
    expect(fd.depositCumulative, isFalse);
    final schedules =
        await db.recurringTransactionsDao.getSchedulesByItem(1, fd.id);
    expect(schedules, hasLength(1));
    expect(schedules.single.recurringType, fixedDepositInterestType);
  });

  testWidgets('FD details show the maturity estimate and edit the deposit',
      (tester) async {
    await openForm(tester, recurring: false);
    await tester.enterText(find.byType(TextFormField).at(0), '10000');
    await tester.enterText(find.byType(TextFormField).at(1), '7.5');
    await tester.enterText(find.byType(TextFormField).at(3), 'Example Bank');
    await tester.enterText(find.byType(TextFormField).at(4), 'A User');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final items = await db.financialItemsDao.getItemsByProfile(1);
    final fd = items.singleWhere((item) => item.subType == 'fixed_deposit');
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(home: DepositDetailsScreen(holding: fd)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Maturity amount'), findsOneWidget);
    expect(find.text('Estimated interest'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit deposit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Fixed Deposit'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '12000');
    await tester.enterText(find.byType(TextFormField).at(1), '8.5');
    await tester.enterText(find.byType(TextFormField).at(2), '3');
    await tester.enterText(find.byType(TextFormField).at(3), 'Updated Bank');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final updated = await db.financialItemsDao.getItemById(fd.id);
    expect(updated!.initialValuePaise, 1200000);
    expect(updated.currentValuationPaise, 1200000);
    expect(updated.bankName, 'Updated Bank');
    expect(updated.accountHolder, 'A User');
    expect(updated.interestRateBasisPoints, 850);
    expect(updated.tenureMonths, 36);
    final transactions =
        await db.transactionsDao.getTransactionsByItem(1, fd.id);
    expect(transactions, hasLength(1));
    expect(transactions.single.amountPaise, 1200000);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('RD edit updates installment without resetting posted amounts',
      (tester) async {
    await openForm(tester, recurring: true);
    await tester.enterText(find.byType(TextFormField).at(0), '1000');
    await tester.enterText(find.byType(TextFormField).at(1), '6.5');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final items = await db.financialItemsDao.getItemsByProfile(1);
    final rd = items.singleWhere((item) => item.subType == 'recurring_deposit');
    final currentAmount = rd.currentValuationPaise;
    await openForm(tester, recurring: true, holding: rd);
    await tester.enterText(find.byType(TextFormField).at(0), '1500');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final updated = await db.financialItemsDao.getItemById(rd.id);
    expect(updated!.currentValuationPaise, currentAmount);
    final schedules =
        await db.recurringTransactionsDao.getSchedulesByItem(1, rd.id);
    expect(schedules.single.amountPaise, 150000);
    final transactions =
        await db.transactionsDao.getTransactionsByItem(1, rd.id);
    expect(transactions, hasLength(1));
    final editedRd = updated;
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(home: DepositDetailsScreen(holding: editedRd)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Maturity amount'), findsOneWidget);
    expect(find.text('Estimated interest'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
