import 'package:drift/native.dart';
import 'package:finbalance/app.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/core/widgets/return_to_profiles_button.dart';
import 'package:finbalance/database/app_database.dart';
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

  Widget createTestApp({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hasSelectedInitialProfileProvider.overrideWith((ref) => true),
        ...overrides,
      ],
      child: const FinBalanceApp(),
    );
  }

  group('Contextual FAB & Navigation Flow Tests', () {
    testWidgets(
        'Context-aware circular FAB displays on tabs and changes contextually',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 1. Overview Tab (Index 0)
      final overviewFab = find.byType(FloatingActionButton);
      expect(overviewFab, findsOneWidget);
      final fabWidget0 = tester.widget<FloatingActionButton>(overviewFab);
      expect(fabWidget0.tooltip, 'Quick Add');

      // Tap FAB on Overview -> opens Quick Financial Action sheet
      await tester.tap(overviewFab);
      await tester.pumpAndSettle();
      expect(find.text('Quick Financial Action'), findsOneWidget);
      expect(find.text('Add Mutual Fund Investment'), findsOneWidget);
      expect(find.text('Add Liability / Debt'), findsOneWidget);
      expect(find.text('Record Income'), findsOneWidget);

      // Dismiss sheet
      await tester.tapAt(const Offset(250, 100));
      await tester.pumpAndSettle();

      // 2. Assets Tab (Index 1)
      await tester.tap(find.text('Assets'));
      await tester.pumpAndSettle();
      final assetsFab = find.byType(FloatingActionButton);
      expect(assetsFab, findsOneWidget);
      final fabWidget1 = tester.widget<FloatingActionButton>(assetsFab);
      expect(fabWidget1.tooltip, 'Add Asset');

      // Tap FAB on Assets -> opens Add Asset sheet
      await tester.tap(assetsFab);
      await tester.pumpAndSettle();
      expect(find.text('Add Asset'), findsOneWidget);
      expect(find.text('Mutual Fund Investment Schedule'), findsOneWidget);

      // Dismiss sheet
      await tester.tapAt(const Offset(250, 100));
      await tester.pumpAndSettle();

      // 3. Liabilities Tab (Index 2)
      await tester.tap(find.text('Liabilities'));
      await tester.pumpAndSettle();
      final liabFab = find.byType(FloatingActionButton);
      expect(liabFab, findsOneWidget);
      final fabWidget2 = tester.widget<FloatingActionButton>(liabFab);
      expect(fabWidget2.tooltip, 'Add Liability / Loan');

      // 4. Activity Tab (Index 3)
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      final activityFab = find.byType(FloatingActionButton);
      expect(activityFab, findsOneWidget);
      final fabWidget3 = tester.widget<FloatingActionButton>(activityFab);
      expect(fabWidget3.tooltip, 'Record Activity');

      // Tap FAB on Activity -> opens Record Transaction sheet
      await tester.tap(activityFab);
      await tester.pumpAndSettle();
      expect(find.text('Record Transaction'), findsOneWidget);
      expect(find.text('Add Income'), findsWidgets);
      expect(find.text('Add Expense'), findsWidgets);
      expect(find.text('Record Transfer'), findsOneWidget);

      // Dismiss sheet
      await tester.tapAt(const Offset(250, 100));
      await tester.pumpAndSettle();

      // 5. Settings Tab (Index 4) -> FAB MUST BE NULL
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);

      // Clean disposal
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
        'ReturnToProfilesButton resets initial selection and returns to profile picker',
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

      // Verify dashboard is showing
      expect(find.text('Overview'), findsOneWidget);

      // Find and tap the ReturnToProfilesButton (switch_account_rounded icon)
      final returnButton = find.byType(ReturnToProfilesButton);
      expect(returnButton, findsWidgets);

      await tester.tap(returnButton.first);
      await tester.pumpAndSettle();

      // Verify returned to Profile Selection screen
      expect(container.read(hasSelectedInitialProfileProvider), isFalse);
      expect(find.text('Select a profile to continue'), findsOneWidget);

      // Clean disposal
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
        'NAV synchronization controls exist in Settings and are absent from Assets and Overview',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Overview: Verify no sync button in AppBar
      expect(find.widgetWithIcon(IconButton, Icons.sync_rounded), findsNothing);

      // Assets: Verify no sync button in AppBar
      await tester.tap(find.text('Assets'));
      await tester.pumpAndSettle();
      expect(find.widgetWithIcon(IconButton, Icons.sync_rounded), findsNothing);

      // Settings: Verify full sync section exists
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Data Synchronization'), findsOneWidget);
      expect(find.text('NAV Refresh Policy'), findsOneWidget);
      expect(find.text('Sync Schedule Status'), findsOneWidget);
      expect(find.text('Manual NAV Sync'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Sync Now'), findsOneWidget);

      // Clean disposal
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
