import 'package:drift/native.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/data/nav/models/nav_models.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/features/activity/widgets/add_transaction_dialog.dart';
import 'package:finbalance/features/assets/widgets/add_to_profile_dialog.dart';
import 'package:finbalance/features/liabilities/widgets/add_liability_dialog.dart';
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

  Widget createTestApp(Widget child) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hasSelectedInitialProfileProvider.overrideWith((ref) => true),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Mobile Form UX & Persistent Action Tests', () {
    testWidgets(
        'AddToProfileDialog displays persistent top Save button in AppBar',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testScheme = MutualFundSchemeDetail(
        schemeCode: 125497,
        schemeName: 'Parag Parikh Flexi Cap Fund - Direct Plan - Growth',
        fundHouse: 'PPFAS Mutual Fund',
        planType: 'Direct',
        optionType: 'Growth',
        latestNav: NavRecord(
          date: DateTime(2025, 2, 7),
          navMicroPaise: 82450000,
          rawNav: '82.45',
        ),
        navHistory: [],
      );

      await tester.pumpWidget(
        createTestApp(
          AddToProfileDialog(scheme: testScheme),
        ),
      );
      await tester.pumpAndSettle();

      // Verify persistent top AppBar
      expect(find.byType(AppBar), findsOneWidget);

      // Verify Close action on left
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Verify persistent top Save button on top right
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);

      // Verify inputs in specified order: Scheme -> Amount -> Start Date -> Frequency -> Installments
      expect(find.text('Parag Parikh Flexi Cap Fund - Direct Plan - Growth'),
          findsOneWidget);
      expect(find.text('Amount per installment'), findsOneWidget);
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('Frequency'), findsOneWidget);
      expect(find.text('Number of Installments'), findsOneWidget);

      // Scroll down to verify calculation summary card
      await tester.scrollUntilVisible(
        find.text('SCHEDULE CALCULATION'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('SCHEDULE CALCULATION'), findsOneWidget);
      expect(find.text('Past Installments (Actual)'), findsOneWidget);
      expect(find.text('Future Installments (Planned)'), findsOneWidget);

      // Clean disposal
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
        'AddLiabilityDialog displays persistent top Save button in AppBar',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(
          const AddLiabilityDialog(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar and top Save button
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Add Liability'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);

      // Verify liability fields
      expect(find.text('Liability / Loan Name'), findsOneWidget);
      expect(find.text('Liability Type'), findsOneWidget);
      expect(find.text('Current Outstanding Balance (INR)'), findsOneWidget);
      expect(find.text('Sanctioned Amount (₹)'), findsOneWidget);

      // Clean disposal
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
        'AddTransactionDialog supports Income, Expense, and Transfer recording with top Save',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(
          const AddTransactionDialog(initialType: 'income'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify top Save button
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);

      // Verify type toggles
      expect(find.text('Income'), findsWidgets);
      expect(find.text('Expense'), findsWidgets);
      expect(find.text('Transfer'), findsWidgets);

      // Verify Amount field
      expect(find.text('Transaction Amount'), findsOneWidget);

      // Clean disposal
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
