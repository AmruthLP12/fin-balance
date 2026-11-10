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

  /// Moves mutual fund holdings and their transactions that were filed under
  /// the wrong category (older builds used "Bonds") to Mutual Funds & SIPs.
  Future<void> repairMutualFundCategories() async {
    final id = await mutualFundCategoryId();
    await customUpdate(
      'UPDATE transactions SET category_id = ? WHERE category_id != ? AND '
      'financial_item_id IN (SELECT id FROM financial_items WHERE sub_type = ?)',
      variables: [
        Variable.withInt(id),
        Variable.withInt(id),
        Variable.withString('mutual_fund'),
      ],
      updates: {db.transactions},
    );
    await customUpdate(
      'UPDATE financial_items SET category_id = ? WHERE category_id != ? '
      'AND sub_type = ?',
      variables: [
        Variable.withInt(id),
        Variable.withInt(id),
        Variable.withString('mutual_fund'),
      ],
      updates: {db.financialItems},
    );
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

  /// Get category by id.
  Future<FinancialCategory?> getCategoryById(int id) {
    return (select(financialCategories)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new category.
  Future<int> insertCategory(FinancialCategoriesCompanion category) {
    return into(financialCategories).insert(category);
  }

  /// Update an existing category.
  Future<bool> updateCategory(FinancialCategory category) {
    return update(financialCategories).replace(category);
  }

  /// Archive a category safely (soft delete).
  Future<int> archiveCategory(int id) {
    return (update(financialCategories)..where((tbl) => tbl.id.equals(id)))
        .write(const FinancialCategoriesCompanion(isArchived: Value(true)));
  }

  /// Hard delete a category (only if no references prevent it).
  Future<int> deleteCategory(int id) {
    return (delete(financialCategories)..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}
