import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/financial_categories.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [FinancialCategories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Watch all unarchived categories available to a profile (global categories + profile custom categories).
  Stream<List<FinancialCategory>> watchCategoriesForProfile(
    int? profileId, {
    String? classification,
  }) {
    final query = select(financialCategories)
      ..where((tbl) => tbl.isArchived.equals(false));

    if (profileId != null) {
      query.where(
          (tbl) => tbl.profileId.isNull() | tbl.profileId.equals(profileId));
    } else {
      query.where((tbl) => tbl.profileId.isNull());
    }

    if (classification != null) {
      query.where((tbl) => tbl.classification.equals(classification));
    }

    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Watch all unarchived categories (system-wide).
  Stream<List<FinancialCategory>> watchAllCategories() {
    return (select(financialCategories)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Id of the "Mutual Funds & SIPs" category (not the alphabetically first
  /// asset category, which is "Bonds").
  Future<int> mutualFundCategoryId() async {
    final row = await (select(financialCategories)
          ..where((t) => t.name.equals('Mutual Funds & SIPs'))
          ..limit(1))
        .getSingleOrNull();
    return row?.id ?? 1;
  }

  /// The ledger category each kind of holding belongs to.
  static const _categoryBySubType = {
    'mutual_fund': 'Mutual Funds & SIPs',
    'fixed_deposit': 'Fixed & Recurring Deposits',
    'recurring_deposit': 'Fixed & Recurring Deposits',
    'ppf': 'PPF',
    'sss': 'SSS',
  };

  /// Category id for a holding of [subType] (falls back to the first asset category).
  Future<int> categoryIdForSubType(String subType) async {
    final row = await (select(financialCategories)
          ..where((t) => t.name.equals(_categoryBySubType[subType] ?? ''))
          ..limit(1))
        .getSingleOrNull();
    return row?.id ??
        (await getCategoriesByClassification('asset')).firstOrNull?.id ??
        1;
  }

  /// Moves holdings, their transactions and schedules that were filed under the
  /// wrong category (older builds used "Bonds") to the right one. Safe to repeat.
  Future<void> repairHoldingCategories() async {
    for (final subType in _categoryBySubType.keys) {
      final id = await categoryIdForSubType(subType);
      final vars = [
        Variable.withInt(id),
        Variable.withInt(id),
        Variable.withString(subType),
      ];
      const items = 'SELECT id FROM financial_items WHERE sub_type = ?';
      await customUpdate(
        'UPDATE transactions SET category_id = ? WHERE category_id != ? '
        'AND financial_item_id IN ($items)',
        variables: vars,
        updates: {db.transactions},
      );
      await customUpdate(
        'UPDATE recurring_transactions SET category_id = ? WHERE category_id != ? '
        'AND financial_item_id IN ($items)',
        variables: vars,
        updates: {db.recurringTransactions},
      );
      await customUpdate(
        'UPDATE financial_items SET category_id = ? WHERE category_id != ? '
        'AND sub_type = ?',
        variables: vars,
        updates: {db.financialItems},
      );
    }
  }

  /// Get categories by classification ('asset', 'liability', 'income', 'expense').
  Future<List<FinancialCategory>> getCategoriesByClassification(
    String classification, {
    int? profileId,
  }) {
    final query = select(financialCategories)
      ..where((tbl) =>
          tbl.classification.equals(classification) &
          tbl.isArchived.equals(false));

    if (profileId != null) {
      query.where(
          (tbl) => tbl.profileId.isNull() | tbl.profileId.equals(profileId));
    }

    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.get();
  }

  /// Watch categories by classification.
  Stream<List<FinancialCategory>> watchCategoriesByClassification(
    String classification, {
    int? profileId,
  }) {
    final query = select(financialCategories)
      ..where((tbl) =>
          tbl.classification.equals(classification) &
          tbl.isArchived.equals(false));

    if (profileId != null) {
      query.where(
          (tbl) => tbl.profileId.isNull() | tbl.profileId.equals(profileId));
    }

    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }
}
