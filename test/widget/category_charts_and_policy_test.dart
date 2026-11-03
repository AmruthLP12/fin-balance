import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/app.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/core/providers/nav_providers.dart';
import 'package:finbalance/data/nav/models/nav_models.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/features/assets/screens/mutual_fund_search_screen.dart';
import 'package:finbalance/features/assets/widgets/scheme_details_sheet.dart';
import 'package:finbalance/features/profile/widgets/profile_menu_button.dart';
import 'package:finbalance/features/settings/screens/privacy_policy_screen.dart';
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

  group('Category Charts & Distribution Tests', () {
    testWidgets(
        'Overview renders 3 switchable charts with Assets & Liabilities by Category as default',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final pId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Arun'),
          relationship: drift.Value('Self'),
          isDefault: drift.Value(true),
        ),
      );
      await db.appSettingsDao.setSetting('active_profile_id', pId.toString());

      final categories = await db.select(db.financialCategories).get();
      final cat1 = categories.firstWhere(
        (c) => c.name.toLowerCase().contains('mutual'),
        orElse: () => categories[0],
      );
      final cat2 = categories.firstWhere(
        (c) => c.name.toLowerCase().contains('gold'),
        orElse: () => categories[1],
      );

      // Add 2 active assets in different categories/subtypes
      await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(pId),
          name: const drift.Value('Nippon Small Cap Fund'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(cat1.id),
          currentValuationPaise: const drift.Value(6000000), // ₹60,000
          initialValuePaise: const drift.Value(5000000),
          status: const drift.Value('active'),
        ),
      );

      await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(pId),
          name: const drift.Value('Sovereign Gold Bond'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('gold'),
          categoryId: drift.Value(cat2.id),
          currentValuationPaise: const drift.Value(4000000), // ₹40,000
          initialValuePaise: const drift.Value(3500000),
          status: const drift.Value('active'),
        ),
      );

      // Add a test transaction for Cash Flow verification
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: drift.Value(pId),
          categoryId: drift.Value(cat1.id),
          transactionType: const drift.Value('income'),
          amountPaise: const drift.Value(10000000), // ₹1,00,000
          transactionDate: drift.Value(DateTime.now()),
          notes: const drift.Value('Monthly salary'),
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

      // Verify section header and the 3 segment options
      expect(find.text('Distribution & Analytics'), findsOneWidget);
      expect(find.text('Assets & Liabilities'), findsOneWidget);
      expect(find.text('Cash Flow'), findsOneWidget);
      expect(find.text('Portfolio Assets'), findsOneWidget);

      // 1. Verify Default Chart is 'Assets & Liabilities by Category'
      expect(find.text('Assets & Liabilities by Category'), findsOneWidget);
      // Canonical names
      expect(find.text('Mutual Funds / SIP'), findsOneWidget);
      expect(find.text('Gold'), findsOneWidget);
      expect(find.text('₹60,000.00'), findsOneWidget);
      expect(find.text('₹40,000.00'), findsOneWidget);
      expect(find.text('Total Liabilities: ₹0'), findsOneWidget);
      expect(find.textContaining('Home Loan • ₹0'), findsOneWidget);
      expect(find.textContaining('Credit Card Dues • ₹0'), findsOneWidget);

      // 2. Switch to 'Cash Flow' chart
      await tester.tap(find.text('Cash Flow'));
      await tester.pumpAndSettle();
      expect(find.text('Cash Flow Overview'), findsOneWidget);
      expect(find.text('Inflows'), findsOneWidget);
      expect(find.text('SIP Investments'), findsOneWidget);

      // 3. Switch to 'Portfolio Assets' chart
      await tester.tap(find.text('Portfolio Assets'));
      await tester.pumpAndSettle();
      expect(find.text('Asset Category Allocation'), findsOneWidget);
      expect(find.text('60.0%'), findsOneWidget);
      expect(find.text('40.0%'), findsOneWidget);

      // 4. Switch back to 'Assets & Liabilities'
      await tester.tap(find.text('Assets & Liabilities'));
      await tester.pumpAndSettle();
      expect(find.text('Assets & Liabilities by Category'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('Profile Avatar Popup Menu Tests', () {
    testWidgets(
        'Tapping profile avatar opens menu with Switch, Manage, and Add options',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          hasSelectedInitialProfileProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FinBalanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the profile menu avatar button
      final menuButton = find.byType(ProfileMenuButton);
      expect(menuButton, findsWidgets);

      await tester.tap(menuButton.first);
      await tester.pumpAndSettle();

      // Popover menu items must appear
      expect(find.text('Switch Profile'), findsOneWidget);
      expect(find.text('Manage Profiles'), findsOneWidget);
      expect(find.text('Add Family Member'), findsOneWidget);

      // Tap outside (e.g. top left of screen) to dismiss without navigation
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Popover dismissed, still on dashboard
      expect(find.text('Switch Profile'), findsNothing);
      expect(container.read(hasSelectedInitialProfileProvider), isTrue);

      // Tap menu again and select 'Switch Profile'
      await tester.tap(menuButton.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switch Profile'));
      await tester.pumpAndSettle();

      // Returned to family selection screen
      expect(container.read(hasSelectedInitialProfileProvider), isFalse);
      expect(find.text('Family-Wide Financial Overview'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('Privacy Policy & Settings Built-By Tests', () {
    testWidgets(
        'Settings displays dedicated Support section, Built by Amruth L P, and links to revised Privacy Policy',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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

      // Navigate to Settings
      await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
      await tester.pumpAndSettle();

      // Scroll to Support section
      await tester.scrollUntilVisible(find.text('Support'), 300);
      await tester.pumpAndSettle();

      // Verify Support section contents
      expect(find.text('Support'), findsOneWidget);
      expect(find.text('Developer Portfolio'), findsOneWidget);
      expect(find.text('https://amruthlp.vercel.app'), findsOneWidget);
      expect(
          find.text('Contact details will be provided here.'), findsOneWidget);

      // Scroll to About section
      await tester.scrollUntilVisible(find.text('Built by Amruth L P'), 300);
      await tester.pumpAndSettle();

      // Check Built by Amruth L P & Portfolio
      expect(find.text('Built by Amruth L P'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);

      // Tap Privacy Policy tile
      await tester.scrollUntilVisible(find.text('Privacy Policy'), 300);
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      // Verify on Privacy Policy screen
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('Privacy by Design'), findsOneWidget);
      expect(find.text('Introduction & Overview'), findsOneWidget);
      expect(find.text('Information We Collect'), findsOneWidget);

      await tester.scrollUntilVisible(
          find.text('Mutual Fund Market Data & Network Usage'), 300);
      expect(
          find.text('Mutual Fund Market Data & Network Usage'), findsOneWidget);

      await tester.scrollUntilVisible(
          find.text('Financial Data Accuracy & Market Delays'), 300);
      expect(
          find.text('Financial Data Accuracy & Market Delays'), findsOneWidget);

      // Verify Section 13 (Open Source) and CHANGELOG references are removed
      expect(find.textContaining('Open Source & Transparency'), findsNothing);
      expect(find.textContaining('CHANGELOG.md'), findsNothing);
      expect(find.textContaining('GitHub'), findsNothing);
      expect(find.textContaining('git repository'), findsNothing);

      // Verify Support section in policy
      await tester.scrollUntilVisible(
          find.text('https://amruthlp.vercel.app/finbalance_policy'), 300);
      expect(find.text('https://amruthlp.vercel.app/finbalance_policy'),
          findsOneWidget);

      // Verify NO mention of SQLite or MFapi in user copy
      expect(find.textContaining('SQLite'), findsNothing);
      expect(find.textContaining('MFapi'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('Mutual Fund Search Min 3 Chars & Favourite Star Tests', () {
    testWidgets(
        'Mutual fund search enforces 3 chars min, shows prompt, and clears cleanly',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            schemeSearchResultsProvider.overrideWith((ref, query) async {
              if (query.trim().length < 3) return [];
              return [
                const MutualFundSearchResult(
                  schemeCode: 125497,
                  schemeName: 'Axis Small Cap Fund Direct Growth',
                  planType: 'Direct',
                  optionType: 'Growth',
                ),
              ];
            }),
          ],
          child: const MaterialApp(
            home: MutualFundSearchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default state: empty search prompt
      expect(find.text('Search Mutual Funds'), findsOneWidget);

      // Type 2 characters
      await tester.enterText(find.byType(TextField), 'ax');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Expect minimum 3 chars prompt
      expect(
          find.text('Enter at least 3 characters to search'), findsOneWidget);

      // Type 3rd character
      await tester.enterText(find.byType(TextField), 'axi');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Result appears
      expect(find.text('Axis Small Cap Fund Direct Growth'), findsOneWidget);

      // Tap clear icon button
      final clearButton = find.byIcon(Icons.clear_rounded);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Returned to empty search state
      expect(find.text('Search Mutual Funds'), findsOneWidget);
      expect(find.text('Axis Small Cap Fund Direct Growth'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('SchemeDetailsSheet has single favourite star in header only',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final detail = MutualFundSchemeDetail(
        schemeCode: 125497,
        schemeName: 'Axis Bluechip Fund Direct Plan Growth',
        fundHouse: 'Axis Mutual Fund',
        schemeType: 'Open Ended Schemes',
        schemeCategory: 'Equity Scheme - Large Cap Fund',
        planType: 'Direct',
        optionType: 'Growth',
        latestNav: NavRecord(
          date: DateTime(2026, 11, 2),
          navMicroPaise: 54320000,
          rawNav: '54.32',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            schemeDetailsProvider(125497).overrideWith((ref) async => detail),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SchemeDetailsSheet(schemeCode: 125497),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify scheme name and details
      expect(
          find.text('Axis Bluechip Fund Direct Plan Growth'), findsOneWidget);
      expect(find.text('Add to Portfolio Assets'), findsOneWidget);

      // Count favourite star icons: exactly one (in header), none beside the button
      final starIcons = find.byIcon(Icons.star_border_rounded);
      expect(starIcons, findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
