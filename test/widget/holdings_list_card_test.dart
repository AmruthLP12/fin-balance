import 'package:finbalance/features/overview/widgets/holdings_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lists every category even when empty and reports taps',
      (tester) async {
    String? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HoldingsListCard(
            assets: const [],
            liabilities: const [],
            onTap: (subType, {required isLiability}) =>
                tapped = '$subType/$isLiability',
          ),
        ),
      ),
    ));

    for (final label in [
      'Mutual Funds',
      'Stocks & ETFs',
      'Fixed Income',
      'Bonds',
      'Gold',
      'Loans',
      'Other Borrowings',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Nothing added yet'), findsWidgets);

    expect(find.text('Home Loan'), findsNothing);
    await tester.ensureVisible(find.text('Loans'));
    await tester.tap(find.text('Loans'));
    expect(tapped, 'loans/true');
  });
}
