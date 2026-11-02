import 'package:drift/drift.dart';
import 'connection/connection.dart';
import 'daos/accounts_dao.dart';
import 'daos/app_settings_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/financial_items_dao.dart';
import 'daos/mutual_fund_dao.dart';
import 'daos/profiles_dao.dart';
import 'daos/recurring_transactions_dao.dart';
import 'daos/sips_dao.dart';
import 'daos/transactions_dao.dart';
import 'daos/valuations_dao.dart';
import 'tables/app_settings.dart';
import 'tables/financial_accounts.dart';
import 'tables/financial_categories.dart';
import 'tables/financial_items.dart';
import 'tables/financial_profiles.dart';
import 'tables/mutual_fund_schemes.dart';
import 'tables/nav_history.dart';
import 'tables/profile_favorite_schemes.dart';
import 'tables/recurring_transactions.dart';
import 'tables/sip_installments.dart';
import 'tables/sip_plans.dart';
import 'tables/sip_schedule_periods.dart';
import 'tables/transactions.dart';
import 'tables/valuation_history.dart';

part 'app_database.g.dart';

/// Central Drift SQLite database for FinBalance.
@DriftDatabase(
  tables: [
    FinancialProfiles,
    FinancialCategories,
    FinancialAccounts,
    FinancialItems,
    Transactions,
    ValuationHistory,
    RecurringTransactions,
    AppSettings,
    MutualFundSchemes,
    NavHistory,
    ProfileFavoriteSchemes,
    SipPlans,
    SipSchedulePeriods,
    SipInstallments,
  ],
  daos: [
    ProfilesDao,
    CategoriesDao,
    AccountsDao,
    FinancialItemsDao,
    TransactionsDao,
    ValuationsDao,
    RecurringTransactionsDao,
    AppSettingsDao,
    MutualFundDao,
    SipsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? connect());

  /// In-memory constructor for unit and integration testing.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedInitialData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(mutualFundSchemes);
          await m.createTable(navHistory);
        }
        if (from < 3) {
          await m.createTable(profileFavoriteSchemes);
          await m.createTable(sipPlans);
          await m.createTable(sipSchedulePeriods);
          await m.createTable(sipInstallments);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Populate core default profile, categories, and settings on fresh database creation.
  Future<void> _seedInitialData() async {
    // 1. Seed initial primary financial profile
    final defaultProfileId = await into(financialProfiles).insert(
      const FinancialProfilesCompanion(
        name: Value('My Profile'),
        relationship: Value('self'),
        colorHex: Value('#10B981'),
        isDefault: Value(true),
        isArchived: Value(false),
      ),
    );

    // 2. Set active profile in application settings
    await into(appSettings).insert(
      AppSettingsCompanion(
        key: const Value('active_profile_id'),
        value: Value(defaultProfileId.toString()),
      ),
    );

    // 3. Seed global baseline categories
    final defaultCategories = <FinancialCategoriesCompanion>[
      // Asset categories
      const FinancialCategoriesCompanion(
        name: Value('Mutual Funds & SIPs'),
        classification: Value('asset'),
        icon: Value('trending_up'),
        colorHex: Value('#10B981'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Stocks & ETFs'),
        classification: Value('asset'),
        icon: Value('show_chart'),
        colorHex: Value('#3B82F6'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Fixed & Recurring Deposits'),
        classification: Value('asset'),
        icon: Value('savings'),
        colorHex: Value('#6366F1'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Gold & Precious Metals'),
        classification: Value('asset'),
        icon: Value('monetization_on'),
        colorHex: Value('#F59E0B'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Retirement (PPF/EPF/NPS)'),
        classification: Value('asset'),
        icon: Value('security'),
        colorHex: Value('#14B8A6'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Cash & Bank Accounts'),
        classification: Value('asset'),
        icon: Value('account_balance'),
        colorHex: Value('#06B6D4'),
      ),

      // Liability categories
      const FinancialCategoriesCompanion(
        name: Value('Home Loans'),
        classification: Value('liability'),
        icon: Value('home'),
        colorHex: Value('#F43F5E'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Vehicle Loans'),
        classification: Value('liability'),
        icon: Value('directions_car'),
        colorHex: Value('#FB7185'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Education Loans'),
        classification: Value('liability'),
        icon: Value('school'),
        colorHex: Value('#E11D48'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Credit Card Dues'),
        classification: Value('liability'),
        icon: Value('credit_card'),
        colorHex: Value('#BE123C'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Personal & Other Loans'),
        classification: Value('liability'),
        icon: Value('money_off'),
        colorHex: Value('#9F1239'),
      ),

      // Cash flow categories
      const FinancialCategoriesCompanion(
        name: Value('Salary & Professional Income'),
        classification: Value('income'),
        icon: Value('payments'),
        colorHex: Value('#10B981'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('General Living Expenses'),
        classification: Value('expense'),
        icon: Value('shopping_cart'),
        colorHex: Value('#64748B'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Investment Allocation'),
        classification: Value('expense'),
        icon: Value('pie_chart'),
        colorHex: Value('#2563EB'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Debt EMI Payment'),
        classification: Value('expense'),
        icon: Value('price_check'),
        colorHex: Value('#F43F5E'),
      ),
    ];

    await batch((b) {
      b.insertAll(financialCategories, defaultCategories);
    });
  }
}
