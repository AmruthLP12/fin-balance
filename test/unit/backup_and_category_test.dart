import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/data/backup/backup_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> seedFund(int categoryId) async {
    final pid = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
            name: drift.Value('A'), relationship: drift.Value('Self')));
    return db.into(db.financialItems).insert(FinancialItemsCompanion(
          profileId: drift.Value(pid),
          name: const drift.Value('Fund'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(categoryId),
          currentValuationPaise: const drift.Value(500),
          startDate: drift.Value(DateTime(2026, 1, 1)),
        ));
  }

  test('mutual fund category is not the alphabetically first one', () async {
    final id = await db.categoriesDao.mutualFundCategoryId();
    final cat = await (db.select(db.financialCategories)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(cat.name, 'Mutual Funds & SIPs');
  });

  test('repair moves misfiled mutual funds out of Bonds', () async {
    final bonds = await (db.select(db.financialCategories)
          ..where((t) => t.name.equals('Bonds')))
        .getSingle();
    final item = await seedFund(bonds.id);
    await db.categoriesDao.repairMutualFundCategories();
    final row = await (db.select(db.financialItems)
          ..where((t) => t.id.equals(item)))
        .getSingle();
    expect(row.categoryId, await db.categoriesDao.mutualFundCategoryId());
  });

  test('backup export then restore reproduces the data', () async {
    await seedFund(await db.categoriesDao.mutualFundCategoryId());
    final bytes = await BackupService(db).export();

    final other = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(other.close);
    final n = await BackupService(other).restore(bytes);
    expect(n, greaterThan(0));
    final items = await other.select(other.financialItems).get();
    expect(items.single.name, 'Fund');
    expect(items.single.currentValuationPaise, 500);
  });

  test('restore rejects files that are not backups', () async {
    expect(() => BackupService(db).restore(utf8.encode('{"a":1}')),
        throwsFormatException);
    expect(() => BackupService(db).restore(utf8.encode('nope')),
        throwsFormatException);
  });
}
