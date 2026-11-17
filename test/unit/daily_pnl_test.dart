import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/core/providers/daily_pnl.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("today's P&L is units x (latest NAV - previous NAV)", () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.mutualFundSchemes).insert(const MutualFundSchemesCompanion(
        schemeCode: drift.Value(77), schemeName: drift.Value('Test Fund')));
    for (final (day, nav) in [(1, 10.0), (2, 10.5), (3, 11.0)]) {
      await db.into(db.navHistory).insert(NavHistoryCompanion(
          schemeCode: const drift.Value(77),
          navDate: drift.Value(DateTime.utc(2026, 1, day)),
          navMicroPaise: drift.Value((nav * 1000000).round())));
    }
    final id = await db.into(db.financialItems).insert(
        const FinancialItemsCompanion(
            profileId: drift.Value(1),
            name: drift.Value('F'),
            itemType: drift.Value('asset'),
            subType: drift.Value('mutual_fund'),
            categoryId: drift.Value(1),
            externalCode: drift.Value('77'),
            unitCountMicroUnits: drift.Value(100 * 1000000)));
    final item = (await db.financialItemsDao.getItemById(id))!;
    // 100 units x ₹0.50 = ₹50 = 5000 paise
    expect(await dailyPnlPaise(db, [item]), 5000);
    expect(await dailyPnlPaise(db, []), isNull);
  });
}
