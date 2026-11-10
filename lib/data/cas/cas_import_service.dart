import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;

import '../../database/app_database.dart';
import '../../database/precision/financial_precision.dart';
import 'cas_parser.dart';

/// A scheme from the AMFI NAV file, found by ISIN.
class AmfiScheme {
  const AmfiScheme(this.code, this.name, this.nav);
  final int code;
  final String name;
  final double nav;
}

class CasImportResult {
  int imported = 0;
  int duplicates = 0;
  int holdings = 0;
}

/// Resolves ISINs to AMFI scheme codes and writes CAS transactions.
class CasImportService {
  CasImportService(this._db, {Dio? dio}) : _dio = dio ?? Dio();

  final AppDatabase _db;
  final Dio _dio;

  /// Downloads the public AMFI NAV file and returns the schemes for [isins].
  /// No personal data is sent; only the public file is fetched.
  Future<Map<String, AmfiScheme>> lookupIsins(Set<String> isins) async {
    final res = await _dio.get<String>(
      'https://portal.amfiindia.com/spages/NAVAll.txt',
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    final found = <String, AmfiScheme>{};
    for (final line in (res.data ?? '').split('\n')) {
      final p = line.trim().split(';');
      if (p.length < 6) continue;
      final code = int.tryParse(p[0]);
      if (code == null) continue;
      for (final isin in [p[1].trim(), p[2].trim()]) {
        if (isins.contains(isin) && !found.containsKey(isin)) {
          found[isin] =
              AmfiScheme(code, p[3].trim(), double.tryParse(p[4]) ?? 0);
        }
      }
    }
    return found;
  }

  /// Saves [folios] under [profileId]. Folios of one scheme share one holding
  /// (FinBalance keeps a holding per scheme). Rows already present (same
  /// date and units on that holding) are skipped, so re-importing is safe.
  Future<CasImportResult> importFolios({
    required int profileId,
    required List<CasFolio> folios,
    required Map<String, AmfiScheme> schemes,
    required DateTime periodStart,
  }) async {
    final result = CasImportResult();
    final categoryId = await _db.categoriesDao.mutualFundCategoryId();

    final byIsin = <String, List<CasFolio>>{};
    for (final f in folios) {
      if (schemes.containsKey(f.isin)) (byIsin[f.isin] ??= []).add(f);
    }

    for (final entry in byIsin.entries) {
      final scheme = schemes[entry.key]!;
      await _db.mutualFundDao.upsertScheme(MutualFundSchemesCompanion(
        schemeCode: drift.Value(scheme.code),
        schemeName: drift.Value(scheme.name),
        isin: drift.Value(entry.key),
        latestNavMicroPaise: scheme.nav > 0
            ? drift.Value(FinancialPrecision.navToMicroPaise(scheme.nav))
            : const drift.Value.absent(),
      ));

      final holding = await (_db.select(_db.financialItems)
            ..where((t) =>
                t.profileId.equals(profileId) &
                t.subType.equals('mutual_fund') &
                t.externalCode.equals(scheme.code.toString()) &
                t.status.equals('active')))
          .getSingleOrNull();
      final holdingId = holding?.id ??
          await _db.into(_db.financialItems).insert(FinancialItemsCompanion(
                profileId: drift.Value(profileId),
                name: drift.Value(scheme.name),
                itemType: const drift.Value('asset'),
                subType: const drift.Value('mutual_fund'),
                categoryId: drift.Value(categoryId),
                currentValuationPaise: const drift.Value(0),
                initialValuePaise: const drift.Value(0),
                unitCountMicroUnits: const drift.Value(0),
                externalCode: drift.Value(scheme.code.toString()),
                startDate: drift.Value(periodStart),
                status: const drift.Value('active'),
              ));
      result.holdings++;

      final existing =
          await _db.transactionsDao.getTransactionsByItem(profileId, holdingId);
      final seen = {
        for (final t in existing)
          '${_day(t.transactionDate)}|${t.unitsMicroUnits ?? 0}'
      };
      final hadEarlierHistory =
          existing.any((t) => t.transactionDate.isBefore(periodStart));

      // Rows to write: opening lots first, then dated transactions.
      final rows = <_Row>[];
      for (final f in entry.value) {
        if (f.opening > 0 && !hadEarlierHistory) {
          final cost = f.openingCost;
          rows.add(_Row(
              periodStart,
              'investment_purchase',
              cost,
              0,
              f.opening,
              f.opening == 0 ? 0 : cost / f.opening,
              'Opening balance from CAS (folio ${f.folio})'));
        }
        for (final t in f.txns) {
          rows.add(_Row(t.date, t.type, t.amount, t.charges, t.units, t.price,
              'CAS import (folio ${f.folio}): ${t.description}'));
        }
      }
      rows.sort((a, b) => a.date.compareTo(b.date));

      for (final r in rows) {
        final units = FinancialPrecision.unitsToMicroUnits(r.units);
        if (!seen.add('${_day(r.date)}|$units')) {
          result.duplicates++;
          continue;
        }
        await _db.transactionsDao.recordInvestmentTransaction(
          profileId: profileId,
          financialItemId: holdingId,
          categoryId: categoryId,
          transactionType: r.type,
          transactionDate: r.date,
          amountPaise: FinancialPrecision.rupeesToPaise(r.amount),
          chargesPaise: FinancialPrecision.rupeesToPaise(r.charges),
          unitsMicroUnits: units,
          unitPriceMicroPaise: FinancialPrecision.navToMicroPaise(r.price),
          notes: r.note,
          source: 'cas_import',
        );
        result.imported++;
      }
    }
    return result;
  }

  static String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

class _Row {
  _Row(this.date, this.type, this.amount, this.charges, this.units, this.price,
      this.note);
  final DateTime date;
  final String type;
  final double amount, charges, units, price;
  final String note;
}
