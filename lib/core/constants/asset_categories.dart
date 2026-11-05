/// A top-level category (Assets tab pill / Overview row). Categories with [children]
/// group several instruments, matched through `FinancialItem.subType`.
class CategoryGroup {
  final String value;
  final String label;
  final List<(String, String)> children;

  const CategoryGroup(this.value, this.label, [this.children = const []]);

  bool contains(String subType) => children.isEmpty
      ? subType == value
      : children.any((c) => c.$1 == subType);
}

const assetGroups = <CategoryGroup>[
  CategoryGroup('mutual_fund', 'Mutual Funds'),
  CategoryGroup('stock', 'Stocks & ETFs'),
  CategoryGroup('fixed_income', 'Fixed Income', [
    ('ppf', 'PPF'),
    ('nsc', 'NSC'),
    ('kvp', 'KVP'),
    ('sss', 'SSS (Sukanya Samriddhi)'),
    ('poss', 'POSS (Post Office Savings)'),
    ('fixed_deposit', 'FD (Fixed Deposit)'),
    ('frd', 'FRD (Flexi Recurring Deposit)'),
    ('recurring_deposit', 'RD (Recurring Deposit)'),
  ]),
  CategoryGroup('epf', 'EPF'),
  CategoryGroup('nps', 'NPS'),
  CategoryGroup('pli', 'PLI / Insurance'),
  CategoryGroup('bond', 'Bonds'),
  CategoryGroup('gold', 'Gold'),
  CategoryGroup('other_asset', 'Other Assets'),
];

const liabilityGroups = <CategoryGroup>[
  CategoryGroup('loans', 'Loans', [
    ('home_loan', 'Home Loan'),
    ('vehicle_loan', 'Car Loan'),
    ('business_loan', 'Business Loan'),
    ('loan_against_property', 'Loan Against Property'),
    ('term_loan', 'Term Loan'),
    ('education_loan', 'Education Loan'),
    ('other_loan', 'Other Loan'),
  ]),
  CategoryGroup('other_liability', 'Other Borrowings'),
];

/// The group a stored subType belongs to; unknown subTypes fall into the last group
/// ("Other Assets" / "Other Borrowings").
CategoryGroup groupOf(String subType, List<CategoryGroup> groups) =>
    groups.firstWhere((g) => g.value == subType || g.contains(subType),
        orElse: () => groups.last);

/// Instruments offered when adding a liability (loan types, then other borrowings).
List<(String, String)> get liabilityTypeOptions => [
      ...liabilityGroups.first.children,
      (liabilityGroups.last.value, liabilityGroups.last.label),
    ];

String categoryLabel(String value) {
  for (final g in [...assetGroups, ...liabilityGroups]) {
    if (g.value == value) return g.label;
    for (final c in g.children) {
      if (c.$1 == value) return c.$2;
    }
  }
  return value
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
