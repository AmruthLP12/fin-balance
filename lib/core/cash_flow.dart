/// How a transaction type moves money, for the ledger and cash flow views.
enum MoneyFlow { income, expense, investment, none }

MoneyFlow flowOf(String type) {
  switch (type) {
    case 'income':
    case 'interest_received':
    case 'lend_repaid':
    case 'borrowing_received':
      return MoneyFlow.income;
    case 'expense':
    case 'debt_repayment':
    case 'interest_paid':
      return MoneyFlow.expense;
    case 'investment_purchase':
    case 'sip_investment':
    case 'lend_given':
    case 'voluntary_deposit':
      return MoneyFlow.investment;
    default:
      return MoneyFlow.none;
  }
}

/// Readable name for loan / lending entries; null for everything else.
String? personalFlowLabel(String type) => switch (type) {
      'debt_repayment' => 'Loan / Borrowing Repayment',
      'interest_paid' => 'Interest Paid',
      'borrowing_received' => 'Money Borrowed',
      'lend_given' => 'Money Lent',
      'lend_repaid' => 'Lent Money Returned',
      'interest_received' => 'Interest Received',
      'voluntary_deposit' => 'Voluntary Deposit',
      _ => null,
    };

const _personalTypes = [
  'debt_repayment',
  'interest_paid',
  'borrowing_received',
  'interest_received',
  'lend_repaid',
  'lend_given',
  'voluntary_deposit',
];

/// Breakdown key for loan / lending entries: negative so it never clashes
/// with a category id (-1 for the first type, -2 for the next, ...).
int categoryKeyFor(String type, int categoryId) {
  final i = _personalTypes.indexOf(type);
  return i < 0 ? categoryId : -(i + 1);
}

String? labelForCategoryKey(int key) =>
    key < 0 ? personalFlowLabel(_personalTypes[-key - 1]) : null;
