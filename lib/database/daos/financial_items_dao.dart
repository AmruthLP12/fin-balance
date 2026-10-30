import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/financial_items.dart';

part 'financial_items_dao.g.dart';

@DriftAccessor(tables: [FinancialItems])
class FinancialItemsDao extends DatabaseAccessor<AppDatabase>
    with _$FinancialItemsDaoMixin {
  FinancialItemsDao(super.db);

  /// Watch all active financial items.
  Stream<List<FinancialItem>> watchAllItems() {
    return (select(financialItems)..where((tbl) => tbl.status.equals('active')))
        .watch();
  }

  /// Watch items by itemType ('asset' or 'liability').
  Stream<List<FinancialItem>> watchItemsByType(String itemType) {
    return (select(financialItems)
          ..where((tbl) =>
              tbl.itemType.equals(itemType) & tbl.status.equals('active')))
        .watch();
  }

  /// Get all items by itemType ('asset' or 'liability').
  Future<List<FinancialItem>> getItemsByType(String itemType) {
    return (select(financialItems)
          ..where((tbl) =>
              tbl.itemType.equals(itemType) & tbl.status.equals('active')))
        .get();
  }

  /// Get items by subType (e.g. 'mutual_fund', 'home_loan').
  Future<List<FinancialItem>> getItemsBySubType(String subType) {
    return (select(financialItems)
          ..where((tbl) =>
              tbl.subType.equals(subType) & tbl.status.equals('active')))
        .get();
  }

  /// Find an item by external code (e.g. scheme code).
  Future<FinancialItem?> getItemByExternalCode(String externalCode) {
    return (select(financialItems)
          ..where((tbl) => tbl.externalCode.equals(externalCode)))
        .getSingleOrNull();
  }

  /// Get single item by ID.
  Future<FinancialItem?> getItemById(int id) {
    return (select(financialItems)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new financial item.
  Future<int> insertItem(FinancialItemsCompanion item) {
    return into(financialItems).insert(item);
  }

  /// Update an existing item.
  Future<bool> updateItem(FinancialItem item) {
    return update(financialItems).replace(item);
  }

  /// Update valuation and unit holdings.
  Future<int> updateValuation({
    required int id,
    required int currentValuationPaise,
    int? unitCountMicroUnits,
  }) {
    return (update(financialItems)..where((tbl) => tbl.id.equals(id))).write(
      FinancialItemsCompanion(
        currentValuationPaise: Value(currentValuationPaise),
        unitCountMicroUnits: unitCountMicroUnits != null
            ? Value(unitCountMicroUnits)
            : const Value.absent(),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Archive an item (soft-delete).
  Future<int> archiveItem(int id) {
    return (update(financialItems)..where((tbl) => tbl.id.equals(id))).write(
      FinancialItemsCompanion(
        status: const Value('archived'),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Hard delete an item.
  Future<int> deleteItem(int id) {
    return (delete(financialItems)..where((tbl) => tbl.id.equals(id))).go();
  }
}
