import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/app.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/features/assets/screens/assets_screen.dart';
import 'package:finbalance/features/assets/screens/sip_details_screen.dart';
import 'package:finbalance/features/assets/widgets/holding_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Investment List Redesign & Category Navigation Tests', () {
    testWidgets(
        'AssetsScreen displays category navigation pills, compact summary card, and compact holding cards',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final pId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Rahul'),
          relationship: drift.Value('Self'),
          isDefault: drift.Value(true),
        ),
      );
      await db.appSettingsDao.setSetting('active_profile_id', pId.toString());

      final categories = await db.select(db.financialCategories).get();
      final mfCat = categories.firstWhere(
        (c) => c.name.toLowerCase().contains('mutual'),
        orElse: () => categories[0],
      );

      // Add a mutual fund holding
      final hId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(pId),
          name: const drift.Value('Parag Parikh Flexi Cap Fund Direct Growth'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(mfCat.id),
          externalCode: const drift.Value('122639'),
          currentValuationPaise: const drift.Value(12500000), // ₹1,25,000
          initialValuePaise: const drift.Value(10000000), // ₹1,00,000
          unitCountMicroUnits: const drift.Value(1850000000), // 1850.000 units
          status: const drift.Value('active'),
        ),
      );

      // Add two historical purchase transactions
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: drift.Value(pId),
          categoryId: drift.Value(mfCat.id),
          financialItemId: drift.Value(hId),
          transactionType: const drift.Value('investment_purchase'),
          amountPaise: const drift.Value(5000000), // ₹50,000
          transactionDate: drift.Value(DateTime(2024, 1, 15)),
          unitsMicroUnits: const drift.Value(1000000000), // 1000 units
          unitPriceMicroPaise: const drift.Value(50000000), // ₹50.00
        ),
      );

      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: drift.Value(pId),
          categoryId: drift.Value(mfCat.id),
          financialItemId: drift.Value(hId),
          transactionType: const drift.Value('investment_purchase'),
          amountPaise: const drift.Value(5000000), // ₹50,000
          transactionDate: drift.Value(DateTime(2024, 6, 15)),
          unitsMicroUnits: const drift.Value(850000000), // 850 units
          unitPriceMicroPaise: const drift.Value(58823529),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            hasSelectedInitialProfileProvider.overrideWith((ref) => true),
          ],
          child: const FinBalanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Assets tab
      await tester.tap(find.widgetWithText(NavigationDestination, 'Assets'));
      await tester.pumpAndSettle();

      // 1. Verify Category Navigation Pills
      expect(find.text('Mutual Funds'), findsWidgets);
      expect(find.text('Stocks & ETFs'), findsOneWidget);
      expect(find.text('Fixed Deposits'), findsOneWidget);
      expect(find.text('Gold'), findsOneWidget);
      expect(find.text('All Assets'), findsOneWidget);

      // 2. Verify Compact Portfolio Summary Card
      expect(find.text('MUTUAL FUNDS SUMMARY'), findsOneWidget);
      expect(find.text('CURRENT VALUE'), findsWidgets);
      expect(find.text('₹1,25,000.00'), findsWidgets); // Both summary and card
      expect(find.textContaining('Invested: '), findsOneWidget);
      expect(find.text('₹1,00,000.00'), findsWidgets);
      expect(find.textContaining('OVERALL P&L'), findsOneWidget);
      expect(find.textContaining('+₹25,000.00 (+25.0%)'), findsOneWidget);
      expect(find.text('+25.0%'), findsOneWidget);

      // 3. Verify Compact Holding Card (No internal transaction history rendered in card)
      expect(find.byType(HoldingCard), findsOneWidget);
      expect(
        find.text('Parag Parikh Flexi Cap Fund Direct Growth'),
        findsOneWidget,
      );
      expect(find.text('INVESTED'), findsWidgets);
      expect(find.text('IRR'), findsWidgets);

      // 4. Test Switching Categories: Switch to 'Stocks & ETFs'
      await tester.tap(find.text('Stocks & ETFs'));
      await tester.pumpAndSettle();

      // Expect intentional empty state for Stocks without crashes
      expect(find.text('No Stocks or ETFs Added'), findsOneWidget);
      expect(find.byType(HoldingCard), findsNothing);

      // Switch back to 'Mutual Funds'
      await tester.tap(find.text('Mutual Funds').first);
      await tester.pumpAndSettle();
      expect(find.byType(HoldingCard), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('Dedicated Full-Screen SipDetailsScreen Navigation & Section Tests',
      () {
    testWidgets(
        'Tapping holding opens dedicated full-screen SipDetailsScreen with Overview, Graph, History, and Schedule',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final pId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Priya'),
          relationship: drift.Value('Self'),
          isDefault: drift.Value(true),
        ),
      );
      await db.appSettingsDao.setSetting('active_profile_id', pId.toString());

      final categories = await db.select(db.financialCategories).get();
      final mfCat = categories.firstWhere(
        (c) => c.name.toLowerCase().contains('mutual'),
        orElse: () => categories[0],
      );

      // Scheme master record
      await db.into(db.mutualFundSchemes).insert(
            MutualFundSchemesCompanion(
              schemeCode: const drift.Value(125497),
              schemeName: const drift.Value(
                  'Axis Small Cap Fund Direct Growth Long Term Equity Plan'),
              fundHouse: const drift.Value('Axis Mutual Fund'),
              planType: const drift.Value('Direct'),
              optionType: const drift.Value('Growth'),
              latestNavMicroPaise: const drift.Value(54320000), // ₹54.3200
              latestNavDate: drift.Value(DateTime(2026, 11, 2)),
              updatedAt: drift.Value(DateTime.now()),
            ),
          );

      // Historical NAV entries
      await db.into(db.navHistory).insert(
            NavHistoryCompanion(
              schemeCode: const drift.Value(125497),
              navDate: drift.Value(DateTime(2026, 10, 1)),
              navMicroPaise: const drift.Value(51000000), // ₹51.00
              sourceProvider: const drift.Value('test'),
            ),
          );
      await db.into(db.navHistory).insert(
            NavHistoryCompanion(
              schemeCode: const drift.Value(125497),
              navDate: drift.Value(DateTime(2026, 11, 2)),
              navMicroPaise: const drift.Value(54320000), // ₹54.32
              sourceProvider: const drift.Value('test'),
            ),
          );

      // Create Holding
      final hId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(pId),
          name: const drift.Value(
              'Axis Small Cap Fund Direct Growth Long Term Equity Plan'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(mfCat.id),
          externalCode: const drift.Value('125497'),
          currentValuationPaise: const drift.Value(5432000), // ₹54,320
          initialValuePaise: const drift.Value(5000000), // ₹50,000
          unitCountMicroUnits: const drift.Value(1000000000), // 1000 units
          status: const drift.Value('active'),
        ),
      );

      // Create SIP Plan & Schedule Period
      final sipId = await db.into(db.sipPlans).insert(
            SipPlansCompanion(
              profileId: drift.Value(pId),
              financialItemId: drift.Value(hId),
              schemeCode: const drift.Value(125497),
              name: const drift.Value('Axis Small Cap Monthly SIP'),
              startDate: drift.Value(DateTime(2024, 1, 5)),
              status: const drift.Value('active'),
            ),
          );

      final periodId = await db.into(db.sipSchedulePeriods).insert(
            SipSchedulePeriodsCompanion(
              sipPlanId: drift.Value(sipId),
              effectiveFrom: drift.Value(DateTime(2024, 1, 5)),
              amountPaise: const drift.Value(500000), // ₹5,000
              deductionDay: const drift.Value(5),
              frequency: const drift.Value('monthly'),
              status: const drift.Value('active'),
            ),
          );

      // Recorded installment + transaction
      final txId = await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: drift.Value(pId),
          categoryId: drift.Value(mfCat.id),
          financialItemId: drift.Value(hId),
          transactionType: const drift.Value('investment_purchase'),
          amountPaise: const drift.Value(5000000), // ₹50,000
          transactionDate: drift.Value(DateTime(2024, 1, 5)),
          unitsMicroUnits: const drift.Value(1000000000),
          unitPriceMicroPaise: const drift.Value(50000000),
        ),
      );

      await db.into(db.sipInstallments).insert(
            SipInstallmentsCompanion(
              sipPlanId: drift.Value(sipId),
              schedulePeriodId: drift.Value(periodId),
              profileId: drift.Value(pId),
              scheduledDate: drift.Value(DateTime(2024, 1, 5)),
              expectedAmountPaise: const drift.Value(5000000),
              actualAmountPaise: const drift.Value(5000000),
              status: const drift.Value('recorded'),
              isSimulated: const drift.Value(false),
              unitsMicroUnits: const drift.Value(1000000000),
              transactionId: drift.Value(txId),
            ),
          );

      // Upcoming future installment
      await db.into(db.sipInstallments).insert(
            SipInstallmentsCompanion(
              sipPlanId: drift.Value(sipId),
              schedulePeriodId: drift.Value(periodId),
              profileId: drift.Value(pId),
              scheduledDate: drift.Value(DateTime(2026, 12, 5)),
              expectedAmountPaise: const drift.Value(500000),
              status: const drift.Value('upcoming'),
              isSimulated: const drift.Value(true),
            ),
          );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            hasSelectedInitialProfileProvider.overrideWith((ref) => true),
          ],
          child: const FinBalanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Assets
      await tester.tap(find.widgetWithText(NavigationDestination, 'Assets'));
      await tester.pumpAndSettle();

      // Tap holding card to navigate to dedicated full-screen page
      await tester.tap(find.byType(HoldingCard));
      await tester.pumpAndSettle();

      // 1. Verify on full-screen SipDetailsScreen (NOT a modal bottom sheet)
      expect(find.byType(SipDetailsScreen), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsNothing);

      // Verify multiline scheme title in AppBar
      expect(
        find.text('Axis Small Cap Fund Direct Growth Long Term Equity Plan'),
        findsWidgets,
      );

      // Verify favorite toggle star is in AppBar actions
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);

      // 2. Section A: Overview Metrics
      expect(find.text('CURRENT VALUATION'), findsOneWidget);
      expect(find.text('₹54,320.00'), findsOneWidget);
      expect(find.text('TOTAL INVESTED'), findsOneWidget);
      expect(find.text('₹50,000.00'), findsOneWidget);
      expect(find.text('PROFIT / LOSS'), findsOneWidget);
      expect(find.text('+₹4,320.00'), findsOneWidget);
      expect(find.text('+8.64% Abs'), findsOneWidget);
      expect(find.text('ANNUALIZED RETURN (XIRR)'), findsOneWidget);
      expect(find.text('UNITS HELD'), findsOneWidget);
      expect(find.text('1000.000'), findsOneWidget);
      expect(find.text('LATEST NAV'), findsOneWidget);
      expect(find.text('₹54.3200'), findsOneWidget);
      expect(find.textContaining('Valuation based on cached NAV of'),
          findsOneWidget);

      // 3. Section B: Performance History Graph
      expect(find.text('Performance History'), findsOneWidget);
      expect(find.text('1M'), findsOneWidget);
      expect(find.text('3M'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);

      // 4. Section C: Transaction History
      expect(find.text('Transaction History (1)'), findsOneWidget);
      expect(find.text('Purchase / Installment'), findsOneWidget);
      expect(find.text('+₹50,000.00'), findsOneWidget);
      expect(find.textContaining('1000.000 units'), findsOneWidget);

      // 5. Section D: SIP Schedule
      expect(find.text('SIP Investment Schedule'), findsOneWidget);
      expect(find.text('Axis Small Cap Monthly SIP'), findsOneWidget);
      expect(find.text('₹5,000.00'), findsOneWidget);
      expect(find.text('MONTHLY'), findsOneWidget);
      expect(find.text('1 Confirmed Investments'), findsOneWidget);
      expect(find.text('1 Planned Future'), findsOneWidget);
      expect(
        find.textContaining(
            'Planned future installments are forward projections and do not contribute to invested capital'),
        findsOneWidget,
      );

      // 6. Test Back Navigation returns to AssetsScreen preserving category selection
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Back on AssetsScreen with Mutual Funds still selected
      expect(find.byType(SipDetailsScreen), findsNothing);
      expect(find.byType(AssetsScreen), findsOneWidget);
      expect(find.text('MUTUAL FUNDS SUMMARY'), findsOneWidget);
      expect(find.byType(HoldingCard), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
