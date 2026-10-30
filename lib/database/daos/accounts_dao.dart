import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/financial_accounts.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [FinancialAccounts])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  /// Watch all unarchived accounts for a specific profile.
  Stream<List<FinancialAccount>> watchAccountsByProfile(
    int profileId, {
    bool includeArchived = false,
  }) {
    final query = select(financialAccounts)
      ..where((tbl) => tbl.profileId.equals(profileId));
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Get all accounts for a specific profile.
  Future<List<FinancialAccount>> getAccountsByProfile(
    int profileId, {
    bool includeArchived = false,
  }) {
    final query = select(financialAccounts)
      ..where((tbl) => tbl.profileId.equals(profileId));
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.get();
  }

  /// Watch all unarchived accounts across all profiles (for household/family overview).
  Stream<List<FinancialAccount>> watchAllActiveAccounts() {
    return (select(financialAccounts)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Get accounts by type for a specific profile.
  Future<List<FinancialAccount>> getAccountsByType(
    int profileId,
    String accountType,
  ) {
    return (select(financialAccounts)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.accountType.equals(accountType) &
              tbl.isArchived.equals(false)))
        .get();
  }

  /// Get account by ID.
  Future<FinancialAccount?> getAccountById(int id) {
    return (select(financialAccounts)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new financial account.
  Future<int> insertAccount(FinancialAccountsCompanion account) {
    return into(financialAccounts).insert(account);
  }

  /// Update an account.
  Future<bool> updateAccount(FinancialAccount account) {
    return update(financialAccounts).replace(account);
  }

  /// Update cached balance.
  Future<int> updateBalance(int accountId, int newBalancePaise) {
    return (update(financialAccounts)..where((tbl) => tbl.id.equals(accountId)))
        .write(FinancialAccountsCompanion(
            currentBalancePaise: Value(newBalancePaise)));
  }

  /// Soft-delete / archive an account.
  Future<int> archiveAccount(int id) {
    return (update(financialAccounts)..where((tbl) => tbl.id.equals(id)))
        .write(const FinancialAccountsCompanion(isArchived: Value(true)));
  }

  /// Hard-delete an account.
  Future<int> deleteAccount(int id) {
    return (delete(financialAccounts)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Calculate total liquid balance in Paise for a profile (bank, cash, wallet).
  Future<int> calculateTotalLiquidityForProfile(int profileId) async {
    final balanceSum = financialAccounts.currentBalancePaise.sum();
    final query = selectOnly(financialAccounts)
      ..addColumns([balanceSum])
      ..where(financialAccounts.profileId.equals(profileId) &
          financialAccounts.isArchived.equals(false) &
          financialAccounts.accountType.isIn(const ['bank', 'cash', 'wallet']));
    final result = await query.map((row) => row.read(balanceSum)).getSingle();
    return result ?? 0;
  }
}
