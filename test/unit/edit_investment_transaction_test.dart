import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/database/precision/financial_precision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late int profileId, categoryId, holdingId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    profileId = await db.profilesDao.createProfile(
      const FinancialProfilesCompanion(
        name: drift.Value('Test'),
        relationship: drift.Value('Self'),
        isDefault: drift.Value(true),
      ),
    );
    final cats = await db.categoriesDao.getCategoriesByClassification('asset');
    categoryId = cats.first.id;
    await db.mutualFundDao.upsertScheme(
      const MutualFundSchemesCompanion(
        schemeCode: drift.Value(1),
        schemeName: drift.Value('Test Fund'),
        latestNavMicroPaise: drift.Value(75000000), // ₹75
      ),
    );
    holdingId = await db.financialItemsDao.insertItem(
      FinancialItemsCompanion(
        profileId: drift.Value(profileId),
        name: const drift.Value('Test Fund'),
        itemType: const drift.Value('asset'),
        subType: const drift.Value('mutual_fund'),
        categoryId: drift.Value(categoryId),
        externalCode: const drift.Value('1'),
      ),
    );
  });

  tearDown(() => db.close());

  Future<int> record(String type, int rupees, int units) =>
      db.transactionsDao.recordInvestmentTransaction(
        profileId: profileId,
        financialItemId: holdingId,
        categoryId: categoryId,
        transactionType: type,
        transactionDate: DateTime(2026, 1, 1),
        amountPaise: rupees * 100,
        unitsMicroUnits: FinancialPrecision.unitsToMicroUnits(units.toDouble()),
      );

  Future<FinancialItem> holding() async =>
      (await db.financialItemsDao.getItemById(holdingId))!;

  test('editing a one-time purchase moves cost, units and value', () async {
    final id = await record('investment_purchase', 10000, 100);
    await db.transactionsDao.updateInvestmentTransaction(
      transactionId: id,
      date: DateTime(2026, 2, 1),
      amountPaise: 1200000,
      unitsMicroUnits: FinancialPrecision.unitsToMicroUnits(120),
      notes: 'fixed',
    );
    final h = await holding();
    expect(h.initialValuePaise, 1200000);
    expect(h.unitCountMicroUnits, FinancialPrecision.unitsToMicroUnits(120));
    expect(h.currentValuationPaise, 120 * 75 * 100); // 120 units at ₹75
    final tx = (await db.transactionsDao.getTransactionById(id))!;
    expect(tx.transactionDate, DateTime(2026, 2, 1));
    expect(tx.notes, 'fixed');
  });

  test('editing a redemption keeps average cost and checks units', () async {
    await record('investment_purchase', 12000, 120);
    final sale = await record('redemption', 4000, 40);
    await db.transactionsDao.updateInvestmentTransaction(
      transactionId: sale,
      date: DateTime(2026, 3, 1),
      amountPaise: 500000,
      unitsMicroUnits: FinancialPrecision.unitsToMicroUnits(50),
    );
    final h = await holding();
    expect(h.unitCountMicroUnits, FinancialPrecision.unitsToMicroUnits(70));
    expect(h.initialValuePaise, 700000); // 70 units at the ₹100 average cost

    expect(
      () => db.transactionsDao.updateInvestmentTransaction(
        transactionId: sale,
        date: DateTime(2026, 3, 1),
        amountPaise: 500000,
        unitsMicroUnits: FinancialPrecision.unitsToMicroUnits(121),
      ),
      throwsArgumentError,
    );
  });

  test('editing the sale of a fully redeemed fund uses the average buy cost',
      () async {
    await record('investment_purchase', 10000, 100);
    final sale = await record('redemption', 12000, 100);
    expect((await holding()).unitCountMicroUnits, 0);
    await db.transactionsDao.updateInvestmentTransaction(
      transactionId: sale,
      date: DateTime(2026, 3, 1),
      amountPaise: 1200000,
      unitsMicroUnits: FinancialPrecision.unitsToMicroUnits(60),
    );
    final h = await holding();
    expect(h.unitCountMicroUnits, FinancialPrecision.unitsToMicroUnits(40));
    expect(h.initialValuePaise, 400000); // 40 units at ₹100
  });
}
