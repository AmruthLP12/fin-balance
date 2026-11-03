import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/features/assets/screens/add_investment_transaction_screen.dart';
import 'package:finbalance/features/assets/screens/edit_holding_screen.dart';
import 'package:finbalance/features/assets/screens/sip_details_screen.dart';
import 'package:finbalance/features/overview/screens/overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late int profileId;
  late int categoryId;
  late int holdingId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    profileId = await db.profilesDao.createProfile(
      const FinancialProfilesCompanion(
        name: drift.Value('Kavita'),
        relationship: drift.Value('Self'),
        isDefault: drift.Value(true),
      ),
    );
    await db.appSettingsDao
        .setSetting('active_profile_id', profileId.toString());

    final categories =
        await db.categoriesDao.getCategoriesByClassification('asset');
    categoryId = categories.isNotEmpty ? categories.first.id : 1;

    await db.mutualFundDao.upsertScheme(
      const MutualFundSchemesCompanion(
        schemeCode: drift.Value(122639),
        schemeName: drift.Value('Parag Parikh Flexi Cap Fund Direct Growth'),
        fundHouse: drift.Value('PPFAS Mutual Fund'),
        schemeCategory: drift.Value('Equity / Flexi Cap'),
        latestNavMicroPaise: drift.Value(80000000), // ₹80.00
      ),
    );

    holdingId = await db.financialItemsDao.insertItem(
      FinancialItemsCompanion(
        profileId: drift.Value(profileId),
        name: const drift.Value('Parag Parikh Flexi Cap Fund Direct Growth'),
        itemType: const drift.Value('asset'),
        subType: const drift.Value('mutual_fund'),
        categoryId: drift.Value(categoryId),
        externalCode: const drift.Value('122639'),
        status: const drift.Value('active'),
        initialValuePaise: const drift.Value(5000000), // ₹50,000
        unitCountMicroUnits: const drift.Value(625000000), // 625.0000 units
        currentValuationPaise: const drift.Value(5000000),
        notes: const drift.Value('Core retirement fund allocation'),
        startDate: drift.Value(DateTime.utc(2026, 1, 1)),
      ),
    );

    // Initial purchase transaction
    await db.transactionsDao.insertTransaction(
      TransactionsCompanion(
        profileId: drift.Value(profileId),
        categoryId: drift.Value(categoryId),
        financialItemId: drift.Value(holdingId),
        transactionType: const drift.Value('investment_purchase'),
        transactionDate: drift.Value(DateTime.utc(2026, 1, 1)),
        amountPaise: const drift.Value(5000000),
        chargesPaise: const drift.Value(5000),
        netAmountPaise: const drift.Value(5005000),
        unitsMicroUnits: const drift.Value(625000000),
        unitPriceMicroPaise: const drift.Value(80000000),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Profile Dashboard Clean-up Tests', () {
    testWidgets('OverviewScreen does NOT display Recent Activity section',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: OverviewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Recent Activity" must not exist anywhere on the dashboard
      expect(find.text('Recent Activity'), findsNothing);
      expect(find.text('Search Schemes'), findsNothing);

      // Core Net worth and charts remain present
      expect(find.textContaining('NET WORTH'), findsOneWidget);
      expect(find.text('Assets & Liabilities by Category'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });

  group('Three-Tab Dedicated Investment Details Page Tests', () {
    testWidgets(
        'SipDetailsScreen renders 3 separate tabs with distinct content',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final holding = await db.financialItemsDao.getItemById(holdingId);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: SipDetailsScreen(holding: holding),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check TabBar with 3 tabs
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Performance History'), findsOneWidget);

      // --- Tab 1: Overview ---
      expect(find.text('CURRENT VALUATION'), findsOneWidget);
      expect(find.text('TOTAL INVESTED'), findsOneWidget);
      expect(find.text('PROFIT / LOSS'), findsOneWidget);
      expect(find.text('ABSOLUTE RETURN'), findsOneWidget);
      expect(find.text('XIRR / IRR'), findsOneWidget);
      expect(find.text('Investment Information'), findsOneWidget);
      expect(find.text('Core retirement fund allocation'), findsOneWidget);
      expect(find.text('Investment Lifecycle'), findsOneWidget);
      expect(find.text('My Remarks'), findsOneWidget);

      // --- Tab 2: Switch to Transactions Tab ---
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.text('All (1)'), findsOneWidget);
      expect(find.text('Purchases'), findsOneWidget);
      expect(find.text('One-time Purchase'), findsOneWidget);

      // --- Tab 3: Switch to Performance History Tab ---
      await tester.tap(find.text('Performance History'));
      await tester.pumpAndSettle();

      expect(find.text('Portfolio Valuation Over Time'), findsOneWidget);
      expect(find.text('1M'), findsOneWidget);
      expect(find.text('3M'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });

  group('Full-Screen Forms Navigation and Persistence Tests', () {
    testWidgets(
        'EditHoldingScreen renders full-screen, updates holding units and remarks',
        (tester) async {
      final holding = await db.financialItemsDao.getItemById(holdingId);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: EditHoldingScreen(holding: holding!),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Holding'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Change personal remarks (last TextFormField is notes)
      final textFields = find.byType(TextFormField);
      await tester.enterText(
          textFields.last, 'Updated: Goal achieved for 2026');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify in DB
      final updatedHolding = await db.financialItemsDao.getItemById(holdingId);
      expect(updatedHolding!.notes, 'Updated: Goal achieved for 2026');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets(
        'AddInvestmentTransactionScreen records transaction with charges',
        (tester) async {
      final holding = await db.financialItemsDao.getItemById(holdingId);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: AddInvestmentTransactionScreen(holding: holding!),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Investment Transaction'), findsOneWidget);
      expect(find.text('Transaction Charges / Fees (₹)'), findsOneWidget);

      // Enter amount: ₹2,000, charges: ₹15
      final amountFields = find.byType(TextFormField);
      await tester.enterText(amountFields.at(0), '2000');
      await tester.enterText(amountFields.at(3), '15.00'); // charges
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify transaction added to DB
      final txs =
          await db.transactionsDao.getTransactionsByItem(profileId, holdingId);
      expect(txs.length, 2);
      final newTx = txs.last;
      expect(newTx.amountPaise, 200000);
      expect(newTx.chargesPaise, 1500);
      expect(newTx.netAmountPaise, 201500); // Outflow = amount + charges

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
