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
      'PPF',
      'NSC',
      'KVP',
      'SSS (Sukanya Samriddhi)',
      'POSS (Post Office Savings)',
      'FD (Fixed Deposit)',
      'FRD (Flexi Recurring Deposit)',
      'RD (Recurring Deposit)',
      'EPF',
      'NPS',
      'PLI / Insurance',
      'Bonds',
      'Gold',
      'Loans',
      'Home Loan',
      'Car Loan',
      'Business Loan',
      'Loan Against Property',
      'Term Loan',
      'Education Loan',
      'Other Loan',
      'Other Borrowings',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Nothing added yet'), findsWidgets);

    await tester.ensureVisible(find.text('Home Loan'));
    await tester.tap(find.text('Home Loan'));
    expect(tapped, 'loans/true');
  });
}
