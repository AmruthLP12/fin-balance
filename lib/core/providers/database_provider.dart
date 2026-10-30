import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../database/daos/accounts_dao.dart';
import '../../database/daos/app_settings_dao.dart';
import '../../database/daos/categories_dao.dart';
import '../../database/daos/financial_items_dao.dart';
import '../../database/daos/mutual_fund_dao.dart';
import '../../database/daos/profiles_dao.dart';
import '../../database/daos/recurring_transactions_dao.dart';
import '../../database/daos/transactions_dao.dart';
import '../../database/daos/valuations_dao.dart';

/// Global provider for the Drift AppDatabase singleton.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final profilesDaoProvider = Provider<ProfilesDao>((ref) {
  return ref.watch(databaseProvider).profilesDao;
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

final mutualFundDaoProvider = Provider<MutualFundDao>((ref) {
  return ref.watch(databaseProvider).mutualFundDao;
});

/// StateNotifier to manage active profile selection and persistence.
class ActiveProfileNotifier extends StateNotifier<int> {
  final Ref _ref;

  ActiveProfileNotifier(this._ref) : super(1) {
    _loadPersistedProfile();
  }

  Future<void> _loadPersistedProfile() async {
    final settingsDao = _ref.read(appSettingsDaoProvider);
    final persistedIdStr = await settingsDao.getSetting('active_profile_id');
    if (persistedIdStr != null) {
      final parsedId = int.tryParse(persistedIdStr);
      if (parsedId != null) {
        state = parsedId;
        return;
      }
    }

    final defaultProfile =
        await _ref.read(profilesDaoProvider).getDefaultProfile();
    if (defaultProfile != null) {
      state = defaultProfile.id;
    }
  }

  /// Switch the active financial profile and persist in AppSettings.
  Future<void> switchProfile(int newProfileId) async {
    state = newProfileId;
    final settingsDao = _ref.read(appSettingsDaoProvider);
    await settingsDao.setSetting('active_profile_id', newProfileId.toString());
  }
}

/// Provider for the currently active profile ID.
final activeProfileIdProvider =
    StateNotifierProvider<ActiveProfileNotifier, int>((ref) {
  return ActiveProfileNotifier(ref);
});

/// Stream provider for all active non-archived profiles (for the profile switcher UI).
final allProfilesProvider = StreamProvider<List<FinancialProfile>>((ref) {
  return ref.watch(profilesDaoProvider).watchAllProfiles();
});

/// Stream provider for the currently selected active profile object.
final activeProfileProvider = StreamProvider<FinancialProfile?>((ref) {
  final activeId = ref.watch(activeProfileIdProvider);
  return ref.watch(profilesDaoProvider).watchProfileById(activeId);
});

/// Stream provider for the active profile's financial accounts.
final activeProfileAccountsProvider =
    StreamProvider<List<FinancialAccount>>((ref) {
  final activeId = ref.watch(activeProfileIdProvider);
  return ref.watch(accountsDaoProvider).watchAccountsByProfile(activeId);
});

/// Stream provider for the active profile's assets.
final activeProfileAssetsProvider = StreamProvider<List<FinancialItem>>((ref) {
  final activeId = ref.watch(activeProfileIdProvider);
  return ref.watch(financialItemsDaoProvider).watchAssetsByProfile(activeId);
});

/// Stream provider for the active profile's liabilities.
final activeProfileLiabilitiesProvider =
    StreamProvider<List<FinancialItem>>((ref) {
  final activeId = ref.watch(activeProfileIdProvider);
  return ref
      .watch(financialItemsDaoProvider)
      .watchLiabilitiesByProfile(activeId);
});

/// Stream provider for the active profile's recent transactions.
final activeProfileTransactionsProvider =
    StreamProvider<List<Transaction>>((ref) {
  final activeId = ref.watch(activeProfileIdProvider);
  return ref
      .watch(transactionsDaoProvider)
      .watchRecentTransactionsForProfile(activeId);
});
