/// One dated line of a CAS folio, already converted to FinBalance semantics.
class CasTxn {
  CasTxn({
    required this.date,
    required this.description,
    required this.amount,
    required this.units,
    required this.price,
    required this.balance,
    required this.type,
    this.charges = 0,
  });

  final DateTime date;
  final String description;

  /// Rupees, always positive.
  final double amount;

  /// Units, always positive; direction comes from [type].
  final double units;
  final double price;
  final double balance;

  /// FinBalance transaction type (see the `transactions` table).
  final String type;

  /// Stamp duty / STT charged on this line, rupees.
  double charges;
}

/// One scheme in one folio, as printed in a CAMS/KFintech CAS.
class CasFolio {
  CasFolio({
    required this.amc,
    required this.folio,
    required this.isin,
    required this.schemeName,
  });

  final String amc;
  final String folio;
  final String isin;
  final String schemeName;
  double opening = 0;
  double closing = 0;
  double totalCost = 0;
  double marketValue = 0;
  final List<CasTxn> txns = [];

  double get _signedUnits =>
      txns.fold(0.0, (s, t) => s + (_isOut(t.type) ? -t.units : t.units));

  /// Opening + statement movements must equal the printed closing balance.
  bool get reconciles => (opening + _signedUnits - closing).abs() < 0.0015;

  /// Cost of the units held before the statement period (unknown from the
  /// transactions, so derived from the printed total cost).
  double get openingCost {
    final bought = txns
        .where((t) => !_isOut(t.type) && t.type != 'dividend_reinvestment')
        .fold(0.0, (s, t) => s + t.amount + t.charges);
    final sold = txns.where((t) => _isOut(t.type));
    // Cost removed by sales is unknowable here; only trust the simple case.
    return sold.isEmpty ? (totalCost - bought).clamp(0, double.infinity) : 0;
  }
}

bool _isOut(String type) =>
    type == 'redemption' || type == 'switch_out' || type == 'swp_withdrawal';

const _num = r'\(?-?[\d,]+\.\d+\)?';
const _date0 = r'(\d{2}-[A-Za-z]{3}-\d{4})';
final _txnRe = RegExp(
    '^$_date0\\s+(.+?)\\s+($_num)\\s+($_num)\\s+($_num)\\s+($_num)\\s*\$');
final _chargeRe = RegExp(
    '^$_date0\\s+\\*{3}\\s*(?:Stamp Duty|STT[^*]*)\\s*\\*{3}\\s+($_num)\\s*\$',
    caseSensitive: false);
final _folioRe = RegExp(r'^Folio No:\s*(\d+(?:\s*/\s*\d+)?)');
final _isinRe = RegExp(r'ISIN\s*:\s*((?:[A-Z0-9]\s*){12})');
final _openRe = RegExp('Opening Unit Balance:\\s*($_num)');
final _closeRe = RegExp('Closing Unit Balance:\\s*($_num)');
final _costRe = RegExp('Total Cost Value:\\s*($_num)');
final _mvRe = RegExp('Market Value on [^:]+:\\s*INR\\s*($_num)');
final _amcRe = RegExp(r'^[A-Za-z][A-Za-z .&-]*(?:Mutual Fund|MUTUAL FUND)\s*$');

double _d(String s) {
  final neg = s.contains('(') || s.contains('-');
  final v = double.parse(s.replaceAll(RegExp(r'[(),\s-]'), ''));
  return neg ? -v : v;
}

const _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

DateTime _date(String s) {
  final p = s.split('-');
  return DateTime(
      int.parse(p[2]), _months[p[1].toLowerCase()]!, int.parse(p[0]));
}

/// Maps a CAS description to a FinBalance transaction type.
String casTxnType(String description, {required bool negativeUnits}) {
  final d = description.toLowerCase();
  if (d.contains('switch')) return negativeUnits ? 'switch_out' : 'switch_in';
  if (d.contains('swp') || d.contains('systematic withdrawal')) {
    return 'swp_withdrawal';
  }
  if (d.contains('reinvest')) return 'dividend_reinvestment';
  if (d.contains('dividend') || d.contains('idcw')) return 'dividend_payout';
  if (negativeUnits || d.contains('redemption')) return 'redemption';
  if (d.contains('sip') || d.contains('systematic') || d.contains('sys.')) {
    return 'sip_investment';
  }
  return 'investment_purchase';
}

/// Parses the text of a CAMS + KFintech CAS into folios. Whitespace-tolerant:
/// works on the text from any extractor as long as rows stay on one line.
List<CasFolio> parseCasText(String text) {
  final folios = <CasFolio>[];
  String amc = '';
  String? folio;
  CasFolio? cur;
  CasTxn? last;

  for (final raw in text.split('\n')) {
    // Extractors differ in spacing; normalise before matching.
    final line = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('( ', '(')
        .replaceAll(' )', ')')
        .trim();
    if (line.isEmpty) continue;

    if (_amcRe.hasMatch(line) && !line.startsWith('Page')) {
      amc = line;
      continue;
    }
    final f = _folioRe.firstMatch(line);
    if (f != null) {
      folio = f.group(1)!.trim();
      cur = null;
      continue;
    }
    final isin = _isinRe.firstMatch(line);
    if (isin != null && folio != null && cur == null) {
      final name = line
          .substring(0, isin.start)
          .replaceFirst(RegExp(r'^\S+?-'), '')
          .replaceFirst(RegExp(r'\s*-\s*$'), '')
          .trim();
      cur = CasFolio(
          amc: amc,
          folio: folio,
          isin: isin.group(1)!.replaceAll(' ', ''),
          schemeName: name);
      folios.add(cur);
      last = null;
    }
    if (cur == null) continue;

    final o = _openRe.firstMatch(line);
    if (o != null) cur.opening = _d(o.group(1)!);
    final c = _closeRe.firstMatch(line);
    if (c != null) {
      cur.closing = _d(c.group(1)!);
      cur.totalCost = _d(_costRe.firstMatch(line)?.group(1) ?? '0');
      cur.marketValue = _d(_mvRe.firstMatch(line)?.group(1) ?? '0');
      continue;
    }
    final ch = _chargeRe.firstMatch(line);
    if (ch != null) {
      last?.charges += _d(ch.group(2)!);
      continue;
    }
    final t = _txnRe.firstMatch(line);
    if (t != null) {
      final units = _d(t.group(4)!);
      last = CasTxn(
        date: _date(t.group(1)!),
        description: t.group(2)!.trim(),
        amount: _d(t.group(3)!).abs(),
        units: units.abs(),
        price: _d(t.group(5)!),
        balance: _d(t.group(6)!),
        type: casTxnType(t.group(2)!, negativeUnits: units < 0),
      );
      cur.txns.add(last);
    }
  }
  return folios;
}

/// Start date printed in the statement header ("01-Apr-2026 To 06-Nov-2026").
DateTime? casPeriodStart(String text) {
  final m = RegExp(r'(\d{2}-[A-Za-z]{3}-\d{4})\s+To\s+\d{2}-[A-Za-z]{3}-\d{4}')
      .firstMatch(text);
  return m == null ? null : _date(m.group(1)!);
}
