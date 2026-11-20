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
      'Other Deposits',
      'Other Assets',
      'Loans',
      'Other Borrowings',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Nothing added yet'), findsWidgets);

    for (final gone in ['EPF', 'NPS', 'Bonds', 'Gold', 'Lent to Others']) {
      expect(find.text(gone), findsNothing);
    }
    expect(find.text('Home Loan'), findsNothing);
    await tester.ensureVisible(find.text('Loans'));
    await tester.tap(find.text('Loans'));
    expect(tapped, 'loans/true');
  });
}
