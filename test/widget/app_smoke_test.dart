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

  testWidgets('FinBalance app boots and displays 5 navigation destinations',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
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

    // Verify app bar title
    expect(find.text('FinBalance'), findsOneWidget);

    // Verify 5 navigation bar destinations
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Assets'), findsOneWidget);
    expect(find.text('Liabilities'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify Overview default content
    expect(find.textContaining('NET WORTH'), findsOneWidget);
    expect(find.text('Total Assets'), findsOneWidget);
    expect(find.text('Total Liabilities'), findsOneWidget);

    // Tap on Assets tab
    await tester.tap(find.text('Assets'));
    await tester.pumpAndSettle();
    expect(find.text('Assets & Holdings'), findsOneWidget);

    // Tap on Liabilities tab
    await tester.tap(find.text('Liabilities'));
    await tester.pumpAndSettle();
    expect(find.text('Liabilities & Debt'), findsOneWidget);

    // Tap on Activity tab
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Activity & Cash Flow'), findsOneWidget);

    // Tap on Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings & Privacy'), findsOneWidget);

    // Dispose widget tree and allow stream cancellation timers to complete
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
