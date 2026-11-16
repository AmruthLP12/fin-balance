import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/features/liabilities/loan_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> loan(int profile, String name, int balance,
      {String status = 'active', DateTime? start, int? years}) {
    return db.into(db.financialItems).insert(FinancialItemsCompanion(
          profileId: drift.Value(profile),
          name: drift.Value(name),
          itemType: const drift.Value('liability'),
          subType: const drift.Value('home_loan'),
          categoryId: const drift.Value(1),
          currentValuationPaise: drift.Value(balance),
          initialValuePaise: const drift.Value(1000000),
          status: drift.Value(status),
          startDate: drift.Value(start),
          tenureYears: drift.Value(years),
        ));
  }

  test('status: term ended with a balance is not Closed', () async {
    final id =
        await loan(1, 'Old', 50000, start: DateTime(2020, 1, 1), years: 1);
    final l = await db.financialItemsDao.getItemById(id);
    expect(LoanCalculator.termEnded(l!), isTrue);
    expect(LoanCalculator.status(l), 'Term ended');
    expect(LoanCalculator.isOngoing(l), isTrue);

    final paid = l.copyWith(currentValuationPaise: 0);
    expect(LoanCalculator.status(paid), 'Closed');
    final closed = l.copyWith(status: 'closed');
    expect(LoanCalculator.isClosed(closed), isTrue);
  });

  test('household totals skip archived profiles; closed loans are not ongoing',
      () async {
    final a = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
            name: drift.Value('A'), relationship: drift.Value('Self')));
    final b = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
            name: drift.Value('B'),
            relationship: drift.Value('Spouse'),
            isArchived: drift.Value(true)));
    await loan(a, 'Ongoing', 100000);
    await loan(a, 'Zero', 0);
    await loan(a, 'Closed', 70000, status: 'closed');
    await loan(b, 'Archived profile loan', 900000);

    final items = await db.select(db.financialItems).get();
    final visible = await db.profilesDao.watchAllProfiles().first;
    final shown = visibleProfilesOnly(items, visible);
    expect(shown.any((i) => i.name == 'Archived profile loan'), isFalse);
    expect(
        shown.where(LoanCalculator.isOngoing).map((i) => i.name), ['Ongoing']);
    expect(shown.where(LoanCalculator.isClosed), hasLength(2));
  });
}
