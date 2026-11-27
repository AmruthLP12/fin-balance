import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/data/assets/recurring_deposit_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late int profileId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    profileId = await db.profilesDao.createProfile(
      const FinancialProfilesCompanion(
        name: drift.Value('Test'),
        relationship: drift.Value('Self'),
        isDefault: drift.Value(true),
      ),
    );
  });

  tearDown(() => db.close());

  Future<FinancialItem> account(int id) async =>
      (await db.financialItemsDao.getItemById(id))!;

  test('balance follows deposits, voluntary deposits and interest', () async {
    final id = await db.transactionsDao.openSavingsAccount(
      profileId: profileId,
      subType: 'ppf',
      name: 'PPF',
      openedOn: DateTime(2026, 4, 1),
      openingPaise: 100000,
    );
    var a = await account(id);
    expect(a.initialValuePaise, 100000);
    expect(a.currentValuationPaise, 100000);

    await db.transactionsDao.recordSavingsEntry(
        itemId: id,
        type: 'voluntary_deposit',
        amountPaise: 50000,
        date: DateTime(2026, 5, 1));
    final interest = await db.transactionsDao.recordSavingsEntry(
        itemId: id,
        type: 'interest_received',
        amountPaise: 7000,
        date: DateTime(2027, 3, 31));
    a = await account(id);
    expect(a.initialValuePaise, 150000); // deposited
    expect(a.currentValuationPaise, 157000); // plus interest

    await db.transactionsDao.updateSavingsEntry(
        transactionId: interest,
        amountPaise: 9000,
        date: DateTime(2027, 3, 31));
    expect((await account(id)).currentValuationPaise, 159000);

    await db.transactionsDao.deleteSavingsEntry(interest);
    a = await account(id);
    expect(a.currentValuationPaise, 150000);

    expect(
        () => db.transactionsDao.recordSavingsEntry(
            itemId: id,
            type: 'interest_received',
            amountPaise: 0,
            date: DateTime(2027, 4, 1)),
        throwsArgumentError);
  });

  test('monthly deduction posts deposits up to today, and can be stopped',
      () async {
    final id = await db.transactionsDao.openSavingsAccount(
      profileId: profileId,
      subType: 'sss',
      name: 'SSS',
      openedOn: DateTime(2026, 1, 1),
      deductionPaise: 100000,
      nextDeduction: DateTime(2026, 2, 10),
    );
    final posted =
        await applyDueDepositTransactions(db, today: DateTime(2026, 4, 15));
    expect(posted, 3); // 10 Feb, 10 Mar, 10 Apr
    var a = await account(id);
    expect(a.initialValuePaise, 300000);
    expect(a.currentValuationPaise, 300000);

    // Running again the same day posts nothing more.
    expect(
        await applyDueDepositTransactions(db, today: DateTime(2026, 4, 15)), 0);

    await db.transactionsDao.setSavingsDeduction(itemId: id);
    expect(
        await applyDueDepositTransactions(db, today: DateTime(2026, 8, 1)), 0);
    a = await account(id);
    expect(a.initialValuePaise, 300000);
  });
}
