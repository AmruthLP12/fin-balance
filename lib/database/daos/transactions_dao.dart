import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  /// Watch recent transactions for a specific profile.
  Stream<List<Transaction>> watchRecentTransactionsForProfile(
    int profileId, {
    int limit = 50,
  }) {
    return (select(transactions)
          ..where((tbl) => tbl.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(limit))
        .watch();
  }

  /// Get recent transactions for a specific profile.
  Future<List<Transaction>> getRecentTransactionsForProfile(
    int profileId, {
    int limit = 50,
  }) {
    return (select(transactions)
          ..where((tbl) => tbl.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(limit))
        .get();
  }

  /// Watch household recent transactions across all profiles.
  Stream<List<Transaction>> watchHouseholdRecentTransactions({int limit = 50}) {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(limit))
        .watch();
  }

  /// Get transactions for a specific profile and item.
  Future<List<Transaction>> getTransactionsByItem(
    int profileId,
    int financialItemId,
  ) {
    return (select(transactions)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
        .get();
  }

  /// Get the earliest / primary investment purchase transaction for a financial item.
  Future<Transaction?> getPrimaryTransactionForItem(
    int profileId,
    int financialItemId,
  ) {
    return (select(transactions)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Watch transactions for a specific profile and item.
  Stream<List<Transaction>> watchTransactionsByItem(
    int profileId,
    int financialItemId,
  ) {
    return (select(transactions)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  /// Get transactions by date range for a specific profile.
  Future<List<Transaction>> getTransactionsByDateRange(
    int profileId,
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.transactionDate.isBiggerOrEqualValue(start) &
              tbl.transactionDate.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
        .get();
  }

  /// Get transaction by ID.
  Future<Transaction?> getTransactionById(int id) {
    return (select(transactions)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Validate cross-profile relationship integrity.
  /// Throws [ArgumentError] if the transaction references an account or item from a different profile.
  Future<void> validateProfileIntegrity(
      TransactionsCompanion transaction) async {
    final profileId = transaction.profileId.value;

    // Check financial item ownership
    if (transaction.financialItemId.present &&
        transaction.financialItemId.value != null) {
      final item = await db.financialItemsDao
          .getItemById(transaction.financialItemId.value!);
      if (item != null && item.profileId != profileId) {
        throw ArgumentError(
            'Cross-profile violation: Financial item ${item.id} belongs to profile ${item.profileId}, but transaction belongs to profile $profileId.');
      }
    }

    // Check fromAccount ownership
    if (transaction.fromAccountId.present &&
        transaction.fromAccountId.value != null) {
      final account =
          await db.accountsDao.getAccountById(transaction.fromAccountId.value!);
      if (account != null && account.profileId != profileId) {
        throw ArgumentError(
            'Cross-profile violation: Account ${account.id} belongs to profile ${account.profileId}, but transaction belongs to profile $profileId.');
      }
    }

    // Check toAccount ownership
    if (transaction.toAccountId.present &&
        transaction.toAccountId.value != null) {
      final account =
          await db.accountsDao.getAccountById(transaction.toAccountId.value!);
      if (account != null && account.profileId != profileId) {
        throw ArgumentError(
            'Cross-profile violation: Account ${account.id} belongs to profile ${account.profileId}, but transaction belongs to profile $profileId.');
      }
    }
  }

  /// Insert a new transaction with profile integrity enforcement.
  Future<int> insertTransaction(TransactionsCompanion transaction) async {
    await validateProfileIntegrity(transaction);
    return into(transactions).insert(transaction);
  }

  /// Update a transaction.
  Future<bool> updateTransaction(Transaction transaction) {
    return update(transactions).replace(transaction);
  }

  /// Delete a transaction.
  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((tbl) => tbl.id.equals(id))).go();
  }
}
