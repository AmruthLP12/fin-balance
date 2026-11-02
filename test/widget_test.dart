import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/app.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/database/app_database.dart';

void main() {
  testWidgets('FinBalance basic widget launch test',
      (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());

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
    expect(find.text('FinBalance'), findsOneWidget);

    // Allow stream cancellation timers to complete
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));

    await db.close();
  });
}
