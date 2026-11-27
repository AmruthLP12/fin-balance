import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/app.dart';
import 'package:finbalance/core/constants/asset_categories.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Deposits group offers the new sub-categories and still owns old ones',
      () {
    final g = assetGroups.firstWhere((g) => g.value == 'other_deposit');
    expect(g.label, 'Deposits');
    expect(g.children.map((c) => c.$2), [
      'FD',
      'RD',
      'PPF',
      'SSS',
      'NSC',
      'Tax Saving Bond',
      'KVP',
      'EPF',
      'Bonds',
      'Gold',
      'NPS',
      'Insurance',
    ]);
    expect(groupOf('frd', assetGroups).value, 'other_deposit');
    expect(groupOf('poss', assetGroups).value, 'other_deposit');
    for (final subType in ['epf', 'bond', 'gold', 'nps']) {
      expect(groupOf(subType, assetGroups).value, 'other_deposit');
    }
  });

  testWidgets('redeemed funds sit in their own hidden section, A to Z',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final pId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
            name: drift.Value('Eve'),
            relationship: drift.Value('Self'),
            isDefault: drift.Value(true)));
    await db.appSettingsDao.setSetting('active_profile_id', pId.toString());
    final cat = await (db.select(db.financialCategories)..limit(1)).getSingle();
    Future<void> fund(String name, int value) =>
        db.financialItemsDao.insertItem(FinancialItemsCompanion(
          profileId: drift.Value(pId),
          name: drift.Value(name),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(cat.id),
          currentValuationPaise: drift.Value(value),
          initialValuePaise: drift.Value(value == 0 ? 100000 : value),
          unitCountMicroUnits: drift.Value(value == 0 ? 0 : 1000000),
        ));
    await fund('Zeta Fund', 500000);
    await fund('Alpha Fund', 300000);
    await fund('Old Redeemed Fund', 0);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hasSelectedInitialProfileProvider.overrideWith((ref) => true),
      ],
      child: const FinBalanceApp(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Assets'));
    await tester.pumpAndSettle();

    expect(find.text('Active (2)'), findsOneWidget);
    expect(find.text('Old Redeemed Fund'), findsNothing);
    expect(tester.getTopLeft(find.text('Alpha Fund')).dy,
        lessThan(tester.getTopLeft(find.text('Zeta Fund')).dy));

    await tester.tap(find.textContaining('Show redeemed (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Old Redeemed Fund'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zeta');
    await tester.pumpAndSettle();
    expect(find.text('Alpha Fund'), findsNothing);
    expect(find.text('Zeta Fund'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets(
      'no All tab; PPF has its own add button; unbuilt chips say coming soon',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final pId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
            name: drift.Value('Eve'),
            relationship: drift.Value('Self'),
            isDefault: drift.Value(true)));
    await db.appSettingsDao.setSetting('active_profile_id', pId.toString());

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hasSelectedInitialProfileProvider.overrideWith((ref) => true),
      ],
      child: const FinBalanceApp(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Assets'));
    await tester.pumpAndSettle();
    expect(find.text('All Assets'), findsNothing);

    await tester.tap(find.text('Deposits'));
    await tester.pumpAndSettle();
    expect(find.text('+ Add PPF'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'PPF'));
    await tester.pumpAndSettle();
    expect(find.text('+ Add PPF'), findsOneWidget);
    expect(find.text('Coming soon'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'SSS'));
    await tester.pumpAndSettle();
    expect(find.text('+ Add SSS'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'NSC'));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.textContaining('+ Add'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('deposits are ordered by nearest maturity date', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final pId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
            name: drift.Value('Eve'),
            relationship: drift.Value('Self'),
            isDefault: drift.Value(true)));
    await db.appSettingsDao.setSetting('active_profile_id', pId.toString());
    final cat = await (db.select(db.financialCategories)..limit(1)).getSingle();
    final year = DateTime.now().year;
    Future<void> deposit(String name, DateTime? matures) =>
        db.financialItemsDao.insertItem(FinancialItemsCompanion(
          profileId: drift.Value(pId),
          name: drift.Value(name),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('fixed_deposit'),
          categoryId: drift.Value(cat.id),
          currentValuationPaise: const drift.Value(100000),
          initialValuePaise: const drift.Value(100000),
          maturityDate: drift.Value(matures),
        ));
    await deposit('Far FD', DateTime(year + 5, 6, 1));
    await deposit('Near FD', DateTime(year + 1, 6, 1));
    await deposit('Undated FD', null);
    await deposit('Matured FD', DateTime(year - 3, 6, 1));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hasSelectedInitialProfileProvider.overrideWith((ref) => true),
      ],
      child: const FinBalanceApp(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Assets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deposits'));
    await tester.pumpAndSettle();

    double y(String name) => tester.getTopLeft(find.text(name)).dy;
    expect(y('Near FD'), lessThan(y('Far FD')));
    expect(y('Far FD'), lessThan(y('Undated FD')));
    expect(y('Undated FD'), lessThan(y('Matured FD')));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
