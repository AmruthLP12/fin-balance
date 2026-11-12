import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/data/cas/cas_import_service.dart';
import 'package:finbalance/data/cas/cas_parser.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

// Invented statement text in the shape CAMS/KFintech print (no real data).
const _cas = '''
Consolidated Account Statement
01-Jan-2026 To 30-Jun-2026
Sample Mutual Fund
Folio No: 1111 / 0
Sample Flexi Cap Fund - Direct Growth (Demat) - ISIN: INF000A01011(Advisor: DIRECT)
Opening Unit Balance: 100.000
05-Jan-2026 Systematic Investment (1) 999.95 10.000 99.9950 110.000
05-Jan-2026 *** Stamp Duty *** 0.05
05-Mar-2026 Redemption (50.00) (5.000) 10.0000 105.000
Closing Unit Balance: 105.000 NAV on 29-Jun-2026: INR 12.0000 Total Cost Value: 11,000.00 Market Value on 29-Jun-2026: INR 1,260.00
Folio No: 2222
Sample Flexi Cap Fund - Direct Growth (Non Demat) - ISIN: INF000A01011
Opening Unit Balance: 0.000
10-Feb-2026 Purchase 500.00 5.000 100.0000 5.000
Closing Unit Balance: 5.000 NAV on 29-Jun-2026: INR 12.0000 Total Cost Value: 500.00 Market Value on 29-Jun-2026: INR 60.00
Folio No: 3333
Broken Fund - ISIN: INF000B02022
Opening Unit Balance: 0.000
10-Feb-2026 Purchase 500.00 5.000 100.0000 9.000
Closing Unit Balance: 9.000 Total Cost Value: 500.00 Market Value on 29-Jun-2026: INR 1.00
''';

void main() {
  summaryTests();
  test('parser reads folios, charges, signs and reconciles units', () {
    final f = parseCasText(_cas);
    expect(f.map((x) => x.folio), ['1111 / 0', '2222', '3333']);
    final a = f.first;
    expect(a.isin, 'INF000A01011');
    expect(a.txns.map((t) => t.type), ['sip_investment', 'redemption']);
    expect(a.txns.first.charges, 0.05);
    expect(a.reconciles, isTrue);
    expect(a.openingCost, 0); // sales present: cost of old lot not guessable
    expect(f[1].reconciles, isTrue);
    expect(f[2].reconciles, isFalse); // 0 + 5 != 9
    expect(casPeriodStart(_cas), DateTime(2026, 1, 1));
  });

  test('import merges folios per scheme and is safe to repeat', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final pid = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
            name: drift.Value('A'), relationship: drift.Value('Self')));
    final svc = CasImportService(db);
    final folios = parseCasText(_cas).where((f) => f.reconciles).toList();
    final schemes = {
      'INF000A01011': const AmfiScheme(123, 'Sample Flexi Cap Direct', 12)
    };

    Future<CasImportResult> run() => svc.importFolios(
        profileId: pid,
        folios: folios,
        schemes: schemes,
        periodStart: DateTime(2026, 1, 1));

    final first = await run();
    final items = await db.select(db.financialItems).get();
    expect(items, hasLength(1));
    // 100 opening + 10 - 5 + 5 = 110 units; 4 txns + opening of folio 1
    expect(items.single.unitCountMicroUnits, 110 * 1000000);
    expect(first.imported, 4);

    final again = await run();
    expect(again.imported, 0);
    expect(again.duplicates, 4);
    expect(
        (await db.select(db.financialItems).get()).single.unitCountMicroUnits,
        110 * 1000000);
  });
}

// Invented "Consolidated Account Summary" rows (holdings only, no transactions).
const _summary = '''
Consolidated Account Summary
As on 12-Nov-2026
Folio No. ISIN Scheme Name Cost Value Unit Balance NAV Date NAV Market Value Registrar
1234567/0 INF000A01011 101ABCD - Sample Flexi Cap Fund Regular 10,000.000 500.000 11-Nov-2026 25.5000 12,750.00 KFINTECH
Growth (Non Demat)
9876 INF000B02022 L 686 G - Sample Small Cap Fund- 4,000.000 301.271 11-Nov-2026 13.38 4,031.01 CAMS
Total 14,000.00 16,781.01
''';

void summaryTests() {
  test('summary statement is read as one opening holding per folio', () {
    final f = parseCasText(_summary);
    expect(f, hasLength(2));
    expect(f.first.summaryOnly, isTrue);
    expect(f.first.folio, '1234567/0');
    expect(f.first.schemeName, startsWith('Sample Flexi Cap'));
    expect(f.first.closing, 500);
    expect(f.first.openingCost, 10000);
    expect(f.every((x) => x.reconciles), isTrue);
    expect(casPeriodStart(_summary), DateTime(2026, 11, 12));
  });

  test('summary import is skipped for a holding that already has data',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final pid = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
            name: drift.Value('A'), relationship: drift.Value('Self')));
    final svc = CasImportService(db);
    final folios = parseCasText(_summary);
    final schemes = {
      'INF000A01011': const AmfiScheme(1, 'Sample Flexi', 25.5),
      'INF000B02022': const AmfiScheme(2, 'Sample Small', 13.38),
    };
    Future<CasImportResult> run() => svc.importFolios(
        profileId: pid,
        folios: folios,
        schemes: schemes,
        periodStart: DateTime(2026, 11, 12));
    final first = await run();
    expect(first.imported, 2);
    final again = await run();
    expect(again.imported, 0);
    final units = (await db.select(db.financialItems).get())
        .map((i) => i.unitCountMicroUnits)
        .toList()
      ..sort();
    expect(units, [301271000, 500000000]);
  });
}
