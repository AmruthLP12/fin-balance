import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/features/assets/screens/add_investment_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late int profileId;
  late int categoryId;
  late int holdingId;
  late FinancialItem holding;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    profileId = await db.profilesDao.createProfile(
      const FinancialProfilesCompanion(
        name: drift.Value('Kavita'),
        relationship: drift.Value('Self'),
        isDefault: drift.Value(true),
      ),
    );
    categoryId = (await db.categoriesDao.getCategoriesByClassification('asset'))
        .first
        .id;
    await db.mutualFundDao.upsertScheme(
      const MutualFundSchemesCompanion(
        schemeCode: drift.Value(122639),
        schemeName: drift.Value('Parag Parikh Flexi Cap Fund Direct Growth'),
        latestNavMicroPaise: drift.Value(80000000),
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
        initialValuePaise: const drift.Value(5000000),
        unitCountMicroUnits: const drift.Value(625000000),
        currentValuationPaise: const drift.Value(5000000),
      ),
    );
    holding = (await db.financialItemsDao.getItemById(holdingId))!;
  });

  tearDown(() => db.close());

  Future<void> openForm(WidgetTester tester,
      {List<SipPlan> sips = const []}) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: AddInvestmentTransactionScreen(holding: holding, sips: sips),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickType(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> closeScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  Future<void> record(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Record Transaction'));
    await tester.tap(find.text('Record Transaction'));
    // The save runs several awaited database calls: let real I/O and fake timers progress.
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  testWidgets(
      'SIP type shows frequency and installments; long SIP name does not overflow',
      (tester) async {
    final sipId = await db.sipsDao.createSipWithPeriod(
      profileId: profileId,
      schemeCode: 122639,
      name:
          'Parag Parikh Flexi Cap Fund Direct Growth Monthly Systematic Investment Plan Long Name',
      startDate: DateTime.utc(2020, 1, 1),
      amountPaise: 100000,
      deductionDay: 1,
      installmentCount: 1,
      financialItemId: holdingId,
    );
    final sip = (await db.sipsDao.getSipById(sipId))!;
    await openForm(tester, sips: [sip]);

    expect(tester.takeException(), isNull, reason: 'overflow on initial open');
    expect(find.text('Frequency'), findsNothing);
    await pickType(tester, 'SIP Investment');

    expect(find.text('Frequency'), findsOneWidget);
    expect(find.text('Number of Installments'), findsOneWidget);
    expect(find.text('Linked SIP'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await closeScreen(tester);
  });

  testWidgets('SIP with 3 installments records the first and plans the rest',
      (tester) async {
    await openForm(tester);
    await pickType(tester, 'SIP Investment');

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '3'); // installments
    await tester.enterText(fields.at(1), '1000'); // amount
    await tester.enterText(fields.at(2), '100'); // NAV
    await tester.pumpAndSettle();
    await record(tester);

    final plans = await db.select(db.sipPlans).get();
    expect(plans, hasLength(1));
    final installments = await db.sipsDao.getInstallments(plans.first.id);
    expect(installments, hasLength(3));
    expect(installments.where((i) => i.status == 'recorded'), hasLength(1));
    expect(installments.where((i) => i.status == 'upcoming'), hasLength(2));

    final txs =
        await db.transactionsDao.getTransactionsByItem(profileId, holdingId);
    expect(txs.single.sipPlanId, plans.first.id);
    await closeScreen(tester);
  });

  testWidgets('SWP with 2 installments creates a plan, records one, plans one',
      (tester) async {
    await openForm(tester);
    await pickType(tester, 'SWP Withdrawal');

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '2');
    await tester.enterText(fields.at(1), '1000');
    await tester.enterText(fields.at(2), '100');
    await tester.pumpAndSettle();
    await record(tester);

    final swps = await db.swpsDao.getSwpsByHolding(holdingId);
    expect(swps, hasLength(1));
    final installments = await db.swpsDao.getInstallments(swps.first.id);
    expect(installments, hasLength(2));
    expect(installments.where((i) => i.status == 'recorded'), hasLength(1));
    expect(installments.where((i) => i.status == 'upcoming'), hasLength(1));

    final txs =
        await db.transactionsDao.getTransactionsByItem(profileId, holdingId);
    expect(txs.single.swpPlanId, swps.first.id);
    await closeScreen(tester);
  });
}
