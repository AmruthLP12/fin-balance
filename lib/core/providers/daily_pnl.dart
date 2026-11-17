import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import 'database_provider.dart';

/// Today's change (paise) across mutual fund holdings: units held times the
/// difference between each scheme's latest and previous NAV. Null when no
/// holding has two NAVs on record yet.
Future<int?> dailyPnlPaise(AppDatabase db, List<FinancialItem> assets) async {
  final units = <int, int>{}; // scheme code -> micro units
  for (final a in assets) {
    final code = int.tryParse(a.externalCode ?? '');
    if (code != null && a.unitCountMicroUnits > 0) {
      units[code] = (units[code] ?? 0) + a.unitCountMicroUnits;
    }
  }
  if (units.isEmpty) return null;
  final rows = await db.customSelect(
    'SELECT scheme_code, nav_micro_paise, rn FROM ('
    'SELECT scheme_code, nav_micro_paise, ROW_NUMBER() OVER '
    '(PARTITION BY scheme_code ORDER BY nav_date DESC) AS rn '
    'FROM nav_history WHERE scheme_code IN (${units.keys.join(',')})'
    ') WHERE rn <= 2',
    readsFrom: {db.navHistory},
  ).get();
  final latest = <int, int>{}, previous = <int, int>{};
  for (final r in rows) {
    final code = r.read<int>('scheme_code');
    final nav = r.read<int>('nav_micro_paise');
    (r.read<int>('rn') == 1 ? latest : previous)[code] = nav;
  }
  int? total;
  for (final e in units.entries) {
    final l = latest[e.key], p = previous[e.key];
    if (l == null || p == null) continue;
    // units/1e6 * (navDiff/1e6 rupees) * 100 paise
    total = (total ?? 0) + (e.value * (l - p) * 100 / 1e12).round();
  }
  return total;
}

final dailyPnlProvider = StreamProvider<int?>((ref) async* {
  final db = ref.watch(databaseProvider);
  final assets = ref.watch(activeProfileAssetsProvider).value ?? [];
  yield await dailyPnlPaise(db, assets);
  yield* db
      .tableUpdates(TableUpdateQuery.onTable(db.navHistory))
      .asyncMap((_) => dailyPnlPaise(db, assets));
});
