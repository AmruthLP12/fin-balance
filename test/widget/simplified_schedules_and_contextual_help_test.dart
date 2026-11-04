import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/core/theme/app_theme.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/features/assets/screens/add_investment_transaction_screen.dart';
import 'package:finbalance/features/assets/screens/sip_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestActiveProfileNotifier extends ActiveProfileNotifier {
  _TestActiveProfileNotifier(super.ref, int initialId) {
    state = initialId;
  }
}

void main() {
  late AppDatabase db;
  late int profileId;
  late int categoryId;
  late FinancialItem testHolding;
  late SipPlan testSip;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    profileId = await db.profilesDao.createProfile(
      const FinancialProfilesCompanion(
        name: drift.Value('Vikram'),
        relationship: drift.Value('Self'),
        isDefault: drift.Value(true),
      ),
    );

    final categories =
        await db.categoriesDao.getCategoriesByClassification('asset');
    categoryId = categories.isNotEmpty ? categories.first.id : 1;

    await db.mutualFundDao.upsertScheme(
      MutualFundSchemesCompanion(
        schemeCode: const drift.Value(122639),
        schemeName:
            const drift.Value('Parag Parikh Flexi Cap Fund Direct Growth'),
        fundHouse: const drift.Value('PPFAS Mutual Fund'),
        latestNavMicroPaise: const drift.Value(75000000),
        latestNavDate: drift.Value(DateTime.utc(2026, 11, 1)),
      ),
    );

    final holdingId = await db.financialItemsDao.insertItem(
      FinancialItemsCompanion(
        profileId: drift.Value(profileId),
        name: const drift.Value('Parag Parikh Flexi Cap Fund'),
        itemType: const drift.Value('asset'),
        subType: const drift.Value('mutual_fund'),
        categoryId: drift.Value(categoryId),
        externalCode: const drift.Value('122639'),
        status: const drift.Value('active'),
        initialValuePaise: const drift.Value(1000000),
        currentValuationPaise: const drift.Value(1200000),
        unitCountMicroUnits: const drift.Value(16000000),
        notes: const drift.Value('Long term goal\nReview after 3 years'),
      ),
    );

    testHolding = (await db.financialItemsDao.getItemById(holdingId))!;

    final sipId = await db.sipsDao.createSipWithPeriod(
      profileId: profileId,
      financialItemId: holdingId,
      schemeCode: 122639,
      name: 'PPFAS Monthly SIP',
      startDate: DateTime.utc(2026, 1, 5),
      amountPaise: 100000,
      deductionDay: 5,
      frequency: 'monthly',
      installmentCount: 12,
    );

    testSip = (await db.sipsDao.getSipById(sipId))!;
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        activeProfileIdProvider
            .overrideWith((ref) => _TestActiveProfileNotifier(ref, profileId)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Contextual Help on Transaction Form Widget Tests', () {
    testWidgets(
        'Transaction form displays Explain Types button and opens modal sheet',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AddInvestmentTransactionScreen(
            holding: testHolding,
            sips: [testSip],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify help button exists
      final helpBtn = find.text('Explain Types');
      expect(helpBtn, findsOneWidget);

      // Tap help button
      await tester.tap(helpBtn);
      await tester.pumpAndSettle();

      // Verify sheet title and content
      expect(find.text('Transaction Type Explanations'), findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(BottomSheet),
              matching: find.text('One-time Investment / Purchase')),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(BottomSheet),
              matching: find.text('SIP Investment')),
          findsOneWidget);
      expect(find.text('IDCW Reinvestment'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('Simplified Schedules & Independent Remarks Widget Tests', () {
    testWidgets('SIP schedule shows minimal format and no verbose counts',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SipDetailsScreen(
            holding: testHolding,
            sip: testSip,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify section header
      expect(find.text('SIP Investment Schedules'), findsOneWidget);
      expect(find.byTooltip('SIP schedule actions'), findsOneWidget);

      // Verify minimal schedule format: SIP · ₹1,000.00 · ...
      expect(find.textContaining('SIP · ₹1,000.00'), findsOneWidget);

      // Verify absence of verbose counts like "1/12" or "Completed" in cards
      expect(find.textContaining('1/12'), findsNothing);
      expect(find.textContaining('Completed 0/12'), findsNothing);

      // Verify distinct Investment Lifecycle and My Remarks cards
      expect(find.text('Investment Lifecycle'), findsOneWidget);
      expect(find.textContaining('SIP started'), findsWidgets);
      expect(find.text('My Remarks'), findsOneWidget);

      // Verify user remarks are displayed point-wise
      expect(find.text('Long term goal'), findsOneWidget);
      expect(find.text('Review after 3 years'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
