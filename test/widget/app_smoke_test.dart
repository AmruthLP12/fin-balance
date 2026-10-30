import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/app.dart';

void main() {
  testWidgets('FinBalance app boots and displays 5 navigation destinations',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FinBalanceApp(),
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
    expect(find.text('TOTAL NET WORTH'), findsOneWidget);
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
  });
}
