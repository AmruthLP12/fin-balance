import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../database/daos/accounts_dao.dart';
import '../../database/daos/app_settings_dao.dart';
import '../../database/daos/categories_dao.dart';
import '../../database/daos/financial_items_dao.dart';
import '../../database/daos/recurring_transactions_dao.dart';
import '../../database/daos/transactions_dao.dart';
import '../../database/daos/valuations_dao.dart';

/// Global provider for the Drift AppDatabase singleton.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final categoriesDaoProvider = Provider<CategoriesDao>((ref) {
  return ref.watch(databaseProvider).categoriesDao;
});

final accountsDaoProvider = Provider<AccountsDao>((ref) {
  return ref.watch(databaseProvider).accountsDao;
});

final financialItemsDaoProvider = Provider<FinancialItemsDao>((ref) {
  return ref.watch(databaseProvider).financialItemsDao;
});

final transactionsDaoProvider = Provider<TransactionsDao>((ref) {
  return ref.watch(databaseProvider).transactionsDao;
});

final valuationsDaoProvider = Provider<ValuationsDao>((ref) {
  return ref.watch(databaseProvider).valuationsDao;
});

final recurringTransactionsDaoProvider =
    Provider<RecurringTransactionsDao>((ref) {
  return ref.watch(databaseProvider).recurringTransactionsDao;
});

final appSettingsDaoProvider = Provider<AppSettingsDao>((ref) {
  return ref.watch(databaseProvider).appSettingsDao;
});
