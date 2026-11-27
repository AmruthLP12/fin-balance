import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/app.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('add a PPF account, then record interest on it', (tester) async {
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
    await tester.tap(find.text('Deposits'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'PPF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Add PPF'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(
            TextFormField, 'Amount deposited on that date (optional)'),
        '1000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final items = await db.financialItemsDao.getItemById(1);
    expect(items!.subType, 'ppf');
    expect(items.currentValuationPaise, 100000);

    await tester.tap(find.text('PPF').last);
    await tester.pumpAndSettle();
    expect(find.text('Balance'), findsOneWidget);
    expect(find.textContaining('Opening deposit'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Interest'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '50');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Interest credited'), findsOneWidget);
    expect((await db.financialItemsDao.getItemById(1))!.currentValuationPaise,
        105000);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
