import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/features/personal_debt/personal_debt_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> openEditForm(WidgetTester tester, FinancialItem item) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  PersonalDebtForm.show(context, lent: true, item: item),
              child: const Text('Open edit'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open edit'));
    await tester.pumpAndSettle();
  }

  testWidgets('editing lent money can switch to Other Assets', (tester) async {
    final id = await db.transactionsDao.openPersonalDebt(
      profileId: 1,
      lent: true,
      person: 'Ravi',
      amountPaise: 500000,
      date: DateTime(2026, 1, 1),
      rateBasisPoints: 200,
    );
    final item = (await db.financialItemsDao.getItemById(id))!;

    await openEditForm(tester, item);
    await tester.tap(find.text('Other Assets'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final updated = (await db.financialItemsDao.getItemById(id))!;
    expect(updated.subType, 'other_asset');
    expect(updated.interestRateBasisPoints, isNull);
    expect(await db.transactionsDao.getTransactionsByItem(1, id), hasLength(1));
  });

  testWidgets('editing an Other Asset can switch to Lent to Others',
      (tester) async {
    final categories =
        await db.categoriesDao.getCategoriesByClassification('asset');
    final category = categories.firstWhere((c) => c.name == 'Other Assets');
    final id = await db.financialItemsDao.insertItem(FinancialItemsCompanion(
      profileId: const drift.Value(1),
      name: const drift.Value('Camera'),
      itemType: const drift.Value('asset'),
      subType: const drift.Value('other_asset'),
      categoryId: drift.Value(category.id),
      initialValuePaise: const drift.Value(250000),
      currentValuationPaise: const drift.Value(250000),
    ));
    final item = (await db.financialItemsDao.getItemById(id))!;

    await openEditForm(tester, item);
    await tester.tap(find.text('Lent to Others'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final updated = (await db.financialItemsDao.getItemById(id))!;
    expect(updated.subType, 'money_lent');
    expect(updated.currentValuationPaise, 250000);
    final transactions = await db.transactionsDao.getTransactionsByItem(1, id);
    expect(transactions, hasLength(1));
    expect(transactions.single.transactionType, 'lend_given');
  });
}
