import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../database/daos/accounts_dao.dart';
import '../../database/daos/app_settings_dao.dart';
import '../../database/daos/categories_dao.dart';
import '../../database/daos/financial_items_dao.dart';
import '../../database/daos/mutual_fund_dao.dart';
import '../../database/daos/profiles_dao.dart';
import '../../database/daos/recurring_transactions_dao.dart';
import '../../database/daos/sips_dao.dart';
import '../../database/daos/swps_dao.dart';
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

final sipsDaoProvider = Provider<SipsDao>((ref) {
  return ref.watch(databaseProvider).sipsDao;
});

final swpsDaoProvider = Provider<SwpsDao>((ref) {
  return ref.watch(databaseProvider).swpsDao;
});

/// Tracks whether the user has picked a profile during this session's startup flow.
/// Selected main tab (0 Overview, 1 Assets, 2 Liabilities, 3 Activity, 4 Settings).
final mainTabProvider = StateProvider<int>((ref) => 0);

/// One-shot request for the Assets tab to show a category (e.g. 'mutual_fund'); consumed by the screen.
final assetsCategoryRequestProvider = StateProvider<String?>((ref) => null);

final hasSelectedInitialProfileProvider = StateProvider<bool>((ref) => false);

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

/// Stream provider for all profiles including archived ones (for Profile Management).
final allProfilesWithArchivedProvider =
    StreamProvider<List<FinancialProfile>>((ref) {
  return ref.watch(profilesDaoProvider).watchAllProfiles(includeArchived: true);
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

/// Stream provider for all active assets across all household profiles.
final householdAssetsProvider = StreamProvider<List<FinancialItem>>((ref) {
  return ref
      .watch(financialItemsDaoProvider)
      .watchHouseholdItems(itemType: 'asset');
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

/// Stream provider for all transactions belonging to a specific item and profile.
final transactionsByItemProvider =
    StreamProvider.family<List<Transaction>, ({int profileId, int itemId})>(
        (ref, arg) {
  return ref
      .watch(transactionsDaoProvider)
      .watchTransactionsByItem(arg.profileId, arg.itemId);
});

/// Stream provider for all SIP plans belonging to the active profile.
final activeProfileSipPlansProvider = StreamProvider<List<SipPlan>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  return ref.watch(sipsDaoProvider).watchSipsByProfile(profileId);
});

/// Stream provider for SIP plans linked to a specific holding/financial item.
final sipsByHoldingProvider =
    StreamProvider.family<List<SipPlan>, int>((ref, holdingId) {
  return ref.watch(sipsDaoProvider).watchSipsByFinancialItem(holdingId);
});

/// Stream provider for periods of a given SIP plan.
final sipPeriodsProvider =
    StreamProvider.family<List<SipSchedulePeriod>, int>((ref, sipPlanId) {
  return ref.watch(sipsDaoProvider).watchSchedulePeriods(sipPlanId);
});

/// Stream provider for installments of a given SIP plan.
final sipInstallmentsProvider =
    StreamProvider.family<List<SipInstallment>, int>((ref, sipPlanId) {
  return ref.watch(sipsDaoProvider).watchInstallments(sipPlanId);
});

/// Stream provider for SWP plans linked to a specific holding/financial item.
final swpsByHoldingProvider =
    StreamProvider.family<List<SwpPlan>, int>((ref, holdingId) {
  return ref.watch(swpsDaoProvider).watchSwpsByHolding(holdingId);
});

/// Stream provider for periods of a given SWP plan.
final swpPeriodsProvider =
    StreamProvider.family<List<SwpSchedulePeriod>, int>((ref, swpPlanId) {
  return ref.watch(swpsDaoProvider).watchSchedulePeriods(swpPlanId);
});

/// Stream provider for installments of a given SWP plan.
final swpInstallmentsProvider =
    StreamProvider.family<List<SwpInstallment>, int>((ref, swpPlanId) {
  return ref.watch(swpsDaoProvider).watchInstallments(swpPlanId);
});

/// Stream provider for all active financial categories.
final allCategoriesProvider = StreamProvider<List<FinancialCategory>>((ref) {
  return ref.watch(categoriesDaoProvider).watchAllCategories();
});

/// Stream provider for categories filtered by profile and classification.
final categoriesForProfileProvider = StreamProvider.family<
    List<FinancialCategory>,
    ({int? profileId, String? classification})>((ref, arg) {
  return ref.watch(categoriesDaoProvider).watchCategoriesForProfile(
      arg.profileId,
      classification: arg.classification);
});
