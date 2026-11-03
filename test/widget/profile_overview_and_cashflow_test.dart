import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/app.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/core/widgets/finbalance_logo.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/features/profile/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Family-Wide Financial Overview & Profile Selection Tests', () {
    testWidgets(
        'ProfileSelectionScreen computes Family Net Worth and renders profile cards',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Create two profiles
      final p1 = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Alice'),
          relationship: drift.Value('Self'),
          isDefault: drift.Value(true),
        ),
      );
      final p2 = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Bob'),
          relationship: drift.Value('Spouse'),
        ),
      );

      // Add asset to Alice (₹50,000)
      final cat =
          await (db.select(db.financialCategories)..limit(1)).getSingle();
      await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(p1),
          name: const drift.Value('Alice MF'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(cat.id),
          currentValuationPaise: const drift.Value(5000000), // ₹50,000
          initialValuePaise: const drift.Value(4000000),
          status: const drift.Value('active'),
        ),
      );

      // Add asset to Bob (₹30,000)
      await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(p2),
          name: const drift.Value('Bob MF'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(cat.id),
          currentValuationPaise: const drift.Value(3000000), // ₹30,000
          initialValuePaise: const drift.Value(2500000),
          status: const drift.Value('active'),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const FinBalanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Top Family Overview verification
      expect(find.text('Family-Wide Financial Overview'), findsOneWidget);
      expect(find.text('Family Net Worth'), findsOneWidget);
      // Family Net Worth and Total Family Assets both equal ₹80,000.00
      expect(find.text('₹80,000.00'), findsNWidgets(2));
      expect(find.text('Total Family Assets'), findsOneWidget);
      expect(find.text('• Upcoming'), findsWidgets);

      // Profile cards
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      // Profile avatar contains initial
      expect(find.text('A'), findsWidgets);
      expect(find.text('B'), findsWidgets);

      // Clean disposal
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('Overview Screen Dashboard Category Allocation & Activity', () {
    testWidgets('Renders net worth and category allocation donut chart',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final pId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Charlie'),
          relationship: drift.Value('Self'),
          isDefault: drift.Value(true),
        ),
      );
      await db.appSettingsDao.setSetting('active_profile_id', pId.toString());

      final cat =
          await (db.select(db.financialCategories)..limit(1)).getSingle();
      await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(pId),
          name: const drift.Value('HDFC Nifty 50 Index Fund'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(cat.id),
          currentValuationPaise: const drift.Value(10000000), // ₹1,00,000
          initialValuePaise: const drift.Value(9000000),
          status: const drift.Value('active'),
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

      // Net worth display
      expect(find.textContaining('NET WORTH'), findsOneWidget);
      expect(find.text('₹1,00,000.00'), findsWidgets);

      // Default unified category chart
      expect(find.text('Assets & Liabilities by Category'), findsOneWidget);

      // Switch to Portfolio Assets and verify donut chart
      await tester.tap(find.text('Portfolio Assets'));
      await tester.pumpAndSettle();
      expect(find.text('Asset Category Allocation'), findsOneWidget);

      // FinBalance clickable logo and ProfileAvatar in header
      expect(find.byType(FinBalanceLogo), findsWidgets);
      expect(find.byType(ProfileAvatar), findsWidgets);

      // Clean disposal
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('SIP Cash Flow Integration Tests', () {
    testWidgets(
        'Cash Flow tab integrates investment_purchase transactions into investment outflows',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final pId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Diana'),
          relationship: drift.Value('Self'),
          isDefault: drift.Value(true),
        ),
      );
      await db.appSettingsDao.setSetting('active_profile_id', pId.toString());

      final cat =
          await (db.select(db.financialCategories)..limit(1)).getSingle();
      final now = DateTime.now();

      // 1. Income: ₹50,000
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion.insert(
          profileId: pId,
          transactionType: 'income',
          categoryId: cat.id,
          transactionDate: now,
          amountPaise: 5000000,
        ),
      );

      // 2. Expense: ₹15,000
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion.insert(
          profileId: pId,
          transactionType: 'expense',
          categoryId: cat.id,
          transactionDate: now,
          amountPaise: 1500000,
        ),
      );

      // 3. Investment Outflow (SIP purchase): ₹10,000
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion.insert(
          profileId: pId,
          transactionType: 'investment_purchase',
          categoryId: cat.id,
          transactionDate: now,
          amountPaise: 1000000,
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

      // Switch to Activity tab
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      // Switch to Cash Flow tab
      await tester.tap(find.text('Cash Flow'));
      await tester.pumpAndSettle();

      // Summary verification:
      // Total Inflow = ₹50,000
      // Expenses = ₹15,000
      // Investment Outflow = ₹10,000
      // Total Outflow = 15k + 10k = ₹25,000
      // Net Cash Movement = 50k - 25k = +₹25,000.00
      expect(find.text('NET CASH MOVEMENT'), findsOneWidget);
      expect(find.text('+₹25,000.00'), findsOneWidget);
      expect(find.text('Total Inflow'), findsOneWidget);
      expect(find.text('Total Outflow'), findsOneWidget);
      expect(find.text('Investments (SIPs)'), findsOneWidget);
      expect(
          find.text('Investment Outflows (SIPs & Purchases)'), findsOneWidget);

      // Clean disposal
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('Category Seed & Migration Tests', () {
    test(
        'Categories seed includes PPF, EPF, GPF, NPS, Bonds without generic Retirement',
        () async {
      final categories = await db.categoriesDao.watchAllCategories().first;
      final names = categories.map((c) => c.name).toList();

      expect(names.contains('PPF'), isTrue);
      expect(names.contains('EPF'), isTrue);
      expect(names.contains('GPF'), isTrue);
      expect(names.contains('NPS'), isTrue);
      expect(names.contains('Bonds'), isTrue);
      expect(names.contains('Other Assets'), isTrue);
      expect(names.contains('Retirement (PPF/EPF/NPS)'), isFalse);
    });
  });
}
