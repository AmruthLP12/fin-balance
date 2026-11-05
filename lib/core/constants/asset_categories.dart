/// Asset categories (stored in `FinancialItem.subType`) in display order, with labels.
/// Shared by the Assets tab pills and the Overview category list.
const assetCategories = <(String, String)>[
  ('mutual_fund', 'Mutual Funds'),
  ('stock', 'Stocks & ETFs'),
  ('fixed_deposit', 'Fixed Deposits'),
  ('recurring_deposit', 'Recurring Deposits'),
  ('ppf', 'PPF'),
  ('epf', 'EPF'),
  ('nps', 'NPS'),
  ('pli', 'PLI / Insurance'),
  ('bond', 'Bonds'),
  ('gold', 'Gold'),
  ('other_asset', 'Other Assets'),
];

/// Liability categories in display order, with labels (matches the add-liability form).
const liabilityCategories = <(String, String)>[
  ('home_loan', 'Home Loan'),
  ('vehicle_loan', 'Vehicle / Auto Loan'),
  ('personal_loan', 'Personal Loan'),
  ('education_loan', 'Education Loan'),
  ('credit_card', 'Credit Card Due'),
  ('other_liability', 'Other Borrowing'),
];

String categoryLabel(String subType) {
  for (final (value, label) in [...assetCategories, ...liabilityCategories]) {
    if (value == subType) return label;
  }
  return subType
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
