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
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Mutual Funds'), findsOneWidget);
    expect(find.text('SIPs'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify Dashboard default content
    expect(find.text('TOTAL NET WORTH'), findsOneWidget);
    expect(find.text('Total Assets'), findsOneWidget);
    expect(find.text('Total Liabilities'), findsOneWidget);

    // Tap on Mutual Funds tab
    await tester.tap(find.text('Mutual Funds'));
    await tester.pumpAndSettle();
    expect(find.text('MUTUAL FUND HOLDINGS'), findsOneWidget);

    // Tap on SIPs tab
    await tester.tap(find.text('SIPs'));
    await tester.pumpAndSettle();
    expect(find.text('SIP Management'), findsOneWidget);

    // Tap on Analytics tab
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Financial Analytics'), findsOneWidget);

    // Tap on Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings & Privacy'), findsOneWidget);
  });
}
