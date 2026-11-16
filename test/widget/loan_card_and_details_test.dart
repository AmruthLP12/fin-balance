import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/app.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loan card opens tabbed details; filter separates closed loans',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final profile = (await db.profilesDao.getDefaultProfile())!;
    Future<void> add(String name, int balance, String status) =>
        db.into(db.financialItems).insert(FinancialItemsCompanion(
              profileId: drift.Value(profile.id),
              name: drift.Value(name),
              itemType: const drift.Value('liability'),
              subType: const drift.Value('home_loan'),
              categoryId: const drift.Value(1),
              currentValuationPaise: drift.Value(balance),
              initialValuePaise: const drift.Value(10000000),
              status: drift.Value(status),
              startDate: drift.Value(DateTime(2026, 1, 1)),
              tenureYears: const drift.Value(2),
            ));
    await add('House loan', 5000000, 'active');
    await add('Old bike loan', 0, 'closed');

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hasSelectedInitialProfileProvider.overrideWith((ref) => true),
      ],
      child: const FinBalanceApp(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Liabilities'));
    await tester.pumpAndSettle();

    // Default filter shows only the ongoing loan, with the remaining amount.
    expect(find.text('Ongoing (1)'), findsOneWidget);
    expect(find.text('Closed (1)'), findsOneWidget);
    expect(find.text('House loan'), findsOneWidget);
    expect(find.text('Old bike loan'), findsNothing);
    expect(find.text('remaining'), findsOneWidget);

    await tester.tap(find.text('Closed (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Old bike loan'), findsOneWidget);
    expect(find.text('House loan'), findsNothing);

    await tester.tap(find.text('Ongoing (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('House loan'));
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('REMAINING BALANCE'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
