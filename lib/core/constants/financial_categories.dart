/// Canonical central category definitions for assets and liabilities across FinBalance.
class FinancialCategoryConstants {
  FinancialCategoryConstants._();

  // Canonical Asset Categories
  static const String mutualFundsSip = 'Mutual Funds / SIP';
  static const String stocks = 'Stocks';
  static const String etfs = 'ETFs';
  static const String fixedDeposits = 'Fixed Deposits (FD)';
  static const String recurringDeposits = 'Recurring Deposits (RD)';
  static const String ppf = 'PPF';
  static const String epf = 'EPF';
  static const String gpf = 'GPF';
  static const String nps = 'NPS';
  static const String gold = 'Gold';
  static const String bonds = 'Bonds';
  static const String bankBalance = 'Bank Balance';
  static const String cash = 'Cash';
  static const String otherAssets = 'Other Assets';

  static const List<String> assetCategories = [
    mutualFundsSip,
    stocks,
    etfs,
    fixedDeposits,
    recurringDeposits,
    ppf,
    epf,
    gpf,
    nps,
    gold,
    bonds,
    bankBalance,
    cash,
    otherAssets,
  ];

  // Canonical Liability Categories
  static const String homeLoan = 'Home Loan';
  static const String personalLoan = 'Personal Loan';
  static const String vehicleLoan = 'Vehicle Loan';
  static const String educationLoan = 'Education Loan';
  static const String creditCardDues = 'Credit Card Dues';
  static const String emiOtherLoanDues = 'EMI / Other Loan Dues';
  static const String otherLiabilities = 'Other Liabilities';

  static const List<String> liabilityCategories = [
    homeLoan,
    personalLoan,
    vehicleLoan,
    educationLoan,
    creditCardDues,
    emiOtherLoanDues,
    otherLiabilities,
  ];

  /// Safely maps raw or legacy database category names / subtypes to canonical names.
  /// Preserves any custom user-created category name if not recognized.
  static String normalizeCategoryName(String rawName, {String? subType}) {
    final clean = rawName.trim();
    final lower = clean.toLowerCase();

    // 1. Asset Category Mappings
    if (lower.contains('mutual') ||
        lower.contains('sip') ||
        subType == 'mutual_fund') {
      return mutualFundsSip;
    }
    if (lower == 'etf' || lower == 'etfs' || subType == 'etf') {
      return etfs;
    }
    if (lower.contains('stock') || subType == 'stock') {
      return stocks;
    }
    if (lower.contains('fixed deposit') ||
        lower.contains('(fd)') ||
        lower == 'fd' ||
        subType == 'fixed_deposit') {
      return fixedDeposits;
    }
    if (lower.contains('recurring deposit') ||
        lower.contains('(rd)') ||
        lower == 'rd' ||
        subType == 'recurring_deposit') {
      return recurringDeposits;
    }
    if (lower.contains('fixed & recurring deposits')) {
      return fixedDeposits;
    }
    if (lower == 'ppf' || subType == 'ppf') {
      return ppf;
    }
    if (lower == 'epf' || subType == 'epf') {
      return epf;
    }
    if (lower == 'gpf' || subType == 'gpf') {
      return gpf;
    }
    if (lower == 'nps' || subType == 'nps') {
      return nps;
    }
    if (lower.contains('gold') || subType == 'gold') {
      return gold;
    }
    if (lower.contains('bond') || subType == 'bond') {
      return bonds;
    }
    if (lower.contains('bank balance') ||
        lower.contains('bank account') ||
        subType == 'bank') {
      return bankBalance;
    }
    if (lower == 'cash' || subType == 'cash') {
      return cash;
    }
    if (lower.contains('cash and bank') ||
        lower.contains('cash & bank') ||
        lower.contains('cash & bank accounts')) {
      return subType == 'cash' ? cash : bankBalance;
    }
    if (lower.contains('retirement')) {
      return ppf;
    }
    if (lower.contains('other asset') || subType == 'other_asset') {
      return otherAssets;
    }

    // 2. Liability Category Mappings
    if (lower.contains('home loan') ||
        lower.contains('home loans') ||
        subType == 'home_loan') {
      return homeLoan;
    }
    if (lower.contains('personal loan') ||
        lower.contains('personal loans') ||
        lower.contains('personal & other loans') ||
        subType == 'personal_loan') {
      return personalLoan;
    }
    if (lower.contains('vehicle loan') ||
        lower.contains('vehicle loans') ||
        subType == 'vehicle_loan') {
      return vehicleLoan;
    }
    if (lower.contains('education loan') ||
        lower.contains('education loans') ||
        subType == 'education_loan') {
      return educationLoan;
    }
    if (lower.contains('credit card') || subType == 'credit_card') {
      return creditCardDues;
    }
    if (lower.contains('emi') ||
        lower.contains('loan due') ||
        subType == 'emi') {
      return emiOtherLoanDues;
    }
    if (lower.contains('other liabilit') || subType == 'other_liability') {
      return otherLiabilities;
    }

    return clean.isNotEmpty ? clean : otherAssets;
  }
}
