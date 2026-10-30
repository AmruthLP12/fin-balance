import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  /// Watch recent transactions ordered descending by date.
  Stream<List<Transaction>> watchRecentTransactions({int limit = 50}) {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(limit))
        .watch();
  }

  /// Get transactions for a specific financial item (e.g. mutual fund holdings or loan payments).
  Future<List<Transaction>> getTransactionsByItem(int financialItemId) {
    return (select(transactions)
          ..where((tbl) => tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
        .get();
  }

  /// Watch transactions for a specific item.
  Stream<List<Transaction>> watchTransactionsByItem(int financialItemId) {
    return (select(transactions)
          ..where((tbl) => tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  /// Get transactions by date range.
  Future<List<Transaction>> getTransactionsByDateRange(
      DateTime start, DateTime end) {
    return (select(transactions)
          ..where((tbl) =>
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

  /// Insert a new transaction.
  Future<int> insertTransaction(TransactionsCompanion transaction) {
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
