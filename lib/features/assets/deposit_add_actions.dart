import 'package:flutter/material.dart';
import '../savings/savings_form.dart';
import 'screens/deposit_form_screen.dart';

/// The add action for a Deposits sub-chip ('fixed_deposit', 'ppf', ...): a label
/// and how to open its form. Null for "All" and for chips not built yet.
({String label, void Function(BuildContext) open})? depositAddFor(String sub) =>
    switch (sub) {
      'fixed_deposit' => (
          label: 'Add FD',
          open: (c) => DepositFormScreen.show(c, recurring: false)
        ),
      'recurring_deposit' => (
          label: 'Add RD',
          open: (c) => DepositFormScreen.show(c, recurring: true)
        ),
      'ppf' => (
          label: 'Add PPF',
          open: (c) => SavingsFormScreen.show(c, subType: 'ppf')
        ),
      'sss' => (
          label: 'Add SSS',
          open: (c) => SavingsFormScreen.show(c, subType: 'sss')
        ),
      _ => null,
    };

/// Deposits chips that can hold records today; every other chip says "coming soon".
const depositChipsBuilt = {
  'all',
  'fixed_deposit',
  'recurring_deposit',
  'ppf',
  'sss'
};
