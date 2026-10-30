import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/financial_items.dart';

part 'financial_items_dao.g.dart';

@DriftAccessor(tables: [FinancialItems])
class FinancialItemsDao extends DatabaseAccessor<AppDatabase>
    with _$FinancialItemsDaoMixin {
  FinancialItemsDao(super.db);

  /// Watch items for a specific profile (optionally filtered by itemType and status).
  Stream<List<FinancialItem>> watchItemsByProfile(
    int profileId, {
    String? itemType,
    String status = 'active',
  }) {
    final query = select(financialItems)
      ..where((tbl) => tbl.profileId.equals(profileId));

    if (itemType != null) {
      query.where((tbl) => tbl.itemType.equals(itemType));
    }
    if (status.isNotEmpty) {
      query.where((tbl) => tbl.status.equals(status));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Get items for a specific profile.
  Future<List<FinancialItem>> getItemsByProfile(
    int profileId, {
    String? itemType,
    String status = 'active',
  }) {
    final query = select(financialItems)
      ..where((tbl) => tbl.profileId.equals(profileId));

    if (itemType != null) {
      query.where((tbl) => tbl.itemType.equals(itemType));
    }
    if (status.isNotEmpty) {
      query.where((tbl) => tbl.status.equals(status));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.get();
  }

  /// Watch active assets for a profile.
  Stream<List<FinancialItem>> watchAssetsByProfile(int profileId) {
    return watchItemsByProfile(profileId, itemType: 'asset', status: 'active');
  }

  /// Watch active liabilities for a profile.
  Stream<List<FinancialItem>> watchLiabilitiesByProfile(int profileId) {
    return watchItemsByProfile(profileId,
        itemType: 'liability', status: 'active');
  }

  /// Watch all active financial items across all profiles (household scope).
  Stream<List<FinancialItem>> watchHouseholdItems({String? itemType}) {
    final query = select(financialItems)
      ..where((tbl) => tbl.status.equals('active'));
    if (itemType != null) {
      query.where((tbl) => tbl.itemType.equals(itemType));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Get items by subType (e.g. 'mutual_fund', 'home_loan') for a profile.
  Future<List<FinancialItem>> getItemsBySubType(
    int profileId,
    String subType,
  ) {
    return (select(financialItems)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.subType.equals(subType) &
              tbl.status.equals('active')))
        .get();
  }

  /// Find an item by external code within a profile.
  Future<FinancialItem?> getItemByExternalCode(
    int profileId,
    String externalCode,
  ) {
    return (select(financialItems)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.externalCode.equals(externalCode)))
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

  /// Calculate net worth for a specific profile (Total Assets - Total Liabilities) in Paise.
  Future<int> calculateNetWorthForProfile(int profileId) async {
    final assetValuationSum = financialItems.currentValuationPaise.sum();
    final assetQuery = selectOnly(financialItems)
      ..addColumns([assetValuationSum])
      ..where(financialItems.profileId.equals(profileId) &
          financialItems.itemType.equals('asset') &
          financialItems.status.equals('active'));
    final assetResult =
        await assetQuery.map((row) => row.read(assetValuationSum)).getSingle();
    final totalAssets = assetResult ?? 0;

    final liabilityValuationSum = financialItems.currentValuationPaise.sum();
    final liabilityQuery = selectOnly(financialItems)
      ..addColumns([liabilityValuationSum])
      ..where(financialItems.profileId.equals(profileId) &
          financialItems.itemType.equals('liability') &
          financialItems.status.equals('active'));
    final liabilityResult = await liabilityQuery
        .map((row) => row.read(liabilityValuationSum))
        .getSingle();
    final totalLiabilities = liabilityResult ?? 0;

    return totalAssets - totalLiabilities;
  }

  /// Calculate combined household net worth in Paise.
  Future<int> calculateHouseholdNetWorth() async {
    final assetValuationSum = financialItems.currentValuationPaise.sum();
    final assetQuery = selectOnly(financialItems)
      ..addColumns([assetValuationSum])
      ..where(financialItems.itemType.equals('asset') &
          financialItems.status.equals('active'));
    final totalAssets = (await assetQuery
            .map((row) => row.read(assetValuationSum))
            .getSingle()) ??
        0;

    final liabilityValuationSum = financialItems.currentValuationPaise.sum();
    final liabilityQuery = selectOnly(financialItems)
      ..addColumns([liabilityValuationSum])
      ..where(financialItems.itemType.equals('liability') &
          financialItems.status.equals('active'));
    final totalLiabilities = (await liabilityQuery
            .map((row) => row.read(liabilityValuationSum))
            .getSingle()) ??
        0;

    return totalAssets - totalLiabilities;
  }
}
