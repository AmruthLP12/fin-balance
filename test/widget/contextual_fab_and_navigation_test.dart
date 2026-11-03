import 'package:drift/native.dart';
import 'package:finbalance/app.dart';
import 'package:finbalance/core/providers/database_provider.dart';
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
      expect(fabWidget0.tooltip, 'Add Investment Schedule');

      // 2. Assets Tab (Index 1)
      await tester.tap(find.widgetWithText(NavigationDestination, 'Assets'));
      await tester.pumpAndSettle();
      final assetsFab = find.byType(FloatingActionButton);
      expect(assetsFab, findsOneWidget);
      final fabWidget1 = tester.widget<FloatingActionButton>(assetsFab);
      expect(fabWidget1.tooltip, 'Add Asset');

      // 3. Liabilities Tab (Index 2) -> FAB Suppressed for milestone scope control
      await tester
          .tap(find.widgetWithText(NavigationDestination, 'Liabilities'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Coming in Future Milestone'), findsOneWidget);

      // 4. Activity Tab (Index 3) -> FAB Suppressed for milestone scope control
      await tester.tap(find.widgetWithText(NavigationDestination, 'Activity'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);

      // 5. Settings Tab (Index 4) -> FAB MUST BE NULL
      await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);

      // Clean disposal
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
        'Clickable logo header resets initial selection and returns to profile picker',
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

      // Find and tap the clickable logo header with Switch Family Profile tooltip
      final logoButton = find.byTooltip('Switch Family Profile');
      expect(logoButton, findsWidgets);

      await tester.tap(logoButton.first);
      await tester.pumpAndSettle();

      // Verify returned to Profile Selection screen
      expect(container.read(hasSelectedInitialProfileProvider), isFalse);
      expect(find.text('Family-Wide Financial Overview'), findsOneWidget);

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
      await tester.tap(find.widgetWithText(NavigationDestination, 'Assets'));
      await tester.pumpAndSettle();
      expect(find.widgetWithIcon(IconButton, Icons.sync_rounded), findsNothing);

      // Settings: Verify full sync section exists
      await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
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
