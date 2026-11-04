import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int sipId;
  late int txId;
  const schemeCode = 125497;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final profileId = await db.profilesDao.createProfile(
      const FinancialProfilesCompanion(
        name: drift.Value('Investor A'),
        relationship: drift.Value('Self'),
      ),
    );
    await db.mutualFundDao.upsertScheme(
      const MutualFundSchemesCompanion(
        schemeCode: drift.Value(schemeCode),
        schemeName: drift.Value('Parag Parikh Flexi Cap Fund'),
      ),
    );
    sipId = await db.sipsDao.createSipWithPeriod(
      profileId: profileId,
      schemeCode: schemeCode,
      name: 'SIP',
      startDate: DateTime.utc(2030, 1, 5),
      amountPaise: 100000,
      deductionDay: 5,
      installmentCount: 3, // 5 Jan, 5 Feb, 5 Mar 2030
    );
    final category =
        (await db.categoriesDao.getCategoriesByClassification('asset')).first;
    txId = await db.transactionsDao.into(db.transactions).insert(
          TransactionsCompanion.insert(
            profileId: profileId,
            transactionType: 'sip_investment',
            categoryId: category.id,
            transactionDate: DateTime.utc(2030, 2, 7),
            amountPaise: 100000,
          ),
        );
  });

  tearDown(() => db.close());

  test('links a SIP transaction to the nearest upcoming installment', () async {
    final linked = await db.sipsDao.linkTransactionToInstallment(
      sipPlanId: sipId,
      transactionId: txId,
      transactionDate: DateTime.utc(2030, 2, 7),
      amountPaise: 100000,
      unitsMicroUnits: 5000000,
    );
    expect(linked, isTrue);

    final byDate = {
      for (final i in await db.sipsDao.getInstallments(sipId))
        i.scheduledDate.month: i,
    };
    expect(byDate[2]!.status, 'recorded');
    expect(byDate[2]!.transactionId, txId);
    expect(byDate[2]!.isSimulated, isFalse);
    expect(byDate[1]!.status, 'upcoming');
    expect(byDate[3]!.status, 'upcoming');
  });

  test('does not link when no installment is within tolerance', () async {
    final linked = await db.sipsDao.linkTransactionToInstallment(
      sipPlanId: sipId,
      transactionId: txId,
      transactionDate: DateTime.utc(2031, 6, 1),
      amountPaise: 100000,
    );
    expect(linked, isFalse);
    final all = await db.sipsDao.getInstallments(sipId);
    expect(all.every((i) => i.status == 'upcoming'), isTrue);
  });
}
