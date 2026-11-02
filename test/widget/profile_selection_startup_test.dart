import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/app.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.profilesDao.createProfile(
      const FinancialProfilesCompanion(
        name: drift.Value('John Doe'),
        relationship: drift.Value('Self'),
        isDefault: drift.Value(true),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
      'Cold startup boots on ProfileSelectionScreen before dashboard loading',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const FinBalanceApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify startup screen header
    expect(find.text('Select a profile to continue'), findsOneWidget);
    expect(find.text('Quick Continue as'), findsOneWidget);
    expect(find.text('John Doe'), findsWidgets);
    expect(find.text('Manage Family Profiles'), findsOneWidget);

    // Tap Quick Continue
    await tester.tap(find.text('Quick Continue as'));
    await tester.pumpAndSettle();

    // Verify transition to main scaffold
    expect(find.text('FinBalance'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Assets'), findsOneWidget);

    // Allow stream cancellation timers to complete
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
