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
import 'daos/swps_dao.dart';
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
import 'tables/swp_installments.dart';
import 'tables/swp_plans.dart';
import 'tables/swp_schedule_periods.dart';
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
    SwpPlans,
    SwpSchedulePeriods,
    SwpInstallments,
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
    SwpsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? connect());

  /// In-memory constructor for unit and integration testing.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 6;

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
        if (from < 4) {
          await m.addColumn(transactions, transactions.chargesPaise);
          await m.addColumn(transactions, transactions.netAmountPaise);
          await m.addColumn(transactions, transactions.sipPlanId);
          await m.addColumn(transactions, transactions.linkedTransactionId);
        }
        if (from < 5) {
          await m.createTable(swpPlans);
          await m.createTable(swpSchedulePeriods);
          await m.createTable(swpInstallments);
          await m.addColumn(transactions, transactions.swpPlanId);
        }
        if (from < 6) {
          await m.addColumn(financialItems, financialItems.lenderName);
          await m.addColumn(financialItems, financialItems.emiPaise);
          await m.addColumn(financialItems, financialItems.tenureYears);
          await m.addColumn(financialItems, financialItems.tenureMonths);
          await m.addColumn(financialItems, financialItems.tenureDays);
          await m.addColumn(financialItems, financialItems.interestRateType);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        await _migrateRetirementCategory();
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
        name: Value('PPF'),
        classification: Value('asset'),
        icon: Value('shield'),
        colorHex: Value('#14B8A6'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('EPF'),
        classification: Value('asset'),
        icon: Value('domain'),
        colorHex: Value('#0EA5E9'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('GPF'),
        classification: Value('asset'),
        icon: Value('account_balance_wallet'),
        colorHex: Value('#059669'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('NPS'),
        classification: Value('asset'),
        icon: Value('account_balance'),
        colorHex: Value('#8B5CF6'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Bonds'),
        classification: Value('asset'),
        icon: Value('receipt_long'),
        colorHex: Value('#D97706'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Cash & Bank Accounts'),
        classification: Value('asset'),
        icon: Value('account_balance'),
        colorHex: Value('#06B6D4'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Other Assets'),
        classification: Value('asset'),
        icon: Value('category'),
        colorHex: Value('#64748B'),
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

  /// Safe migration routine ensuring Retirement category is split into specific
  /// categories (PPF, EPF, GPF, NPS, Bonds, Other Assets) without deleting user data.
  Future<void> _migrateRetirementCategory() async {
    final existingCategories = await select(financialCategories).get();
    final existingNames =
        existingCategories.map((c) => c.name.toLowerCase()).toSet();

    final newSpecificCategories = [
      const FinancialCategoriesCompanion(
        name: Value('PPF'),
        classification: Value('asset'),
        icon: Value('shield'),
        colorHex: Value('#14B8A6'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('EPF'),
        classification: Value('asset'),
        icon: Value('domain'),
        colorHex: Value('#0EA5E9'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('GPF'),
        classification: Value('asset'),
        icon: Value('account_balance_wallet'),
        colorHex: Value('#059669'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('NPS'),
        classification: Value('asset'),
        icon: Value('account_balance'),
        colorHex: Value('#8B5CF6'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Bonds'),
        classification: Value('asset'),
        icon: Value('receipt_long'),
        colorHex: Value('#D97706'),
      ),
      const FinancialCategoriesCompanion(
        name: Value('Other Assets'),
        classification: Value('asset'),
        icon: Value('category'),
        colorHex: Value('#64748B'),
      ),
    ];

    for (final cat in newSpecificCategories) {
      if (!existingNames.contains(cat.name.value.toLowerCase())) {
        await into(financialCategories).insert(cat, onConflict: DoNothing());
      }
    }

    // Check for old Retirement category
    final oldRetirementCategories = existingCategories
        .where((c) => c.name.toLowerCase().contains('retirement'))
        .toList();

    if (oldRetirementCategories.isNotEmpty) {
      final updatedCategories = await select(financialCategories).get();
      int? idFor(String name) => updatedCategories
          .where((c) => c.name.toLowerCase() == name.toLowerCase())
          .firstOrNull
          ?.id;

      final ppfId = idFor('PPF') ?? 1;
      final epfId = idFor('EPF') ?? 1;
      final gpfId = idFor('GPF') ?? 1;
      final npsId = idFor('NPS') ?? 1;
      final otherId = idFor('Other Assets') ?? 1;

      for (final oldCat in oldRetirementCategories) {
        final items = await (select(financialItems)
              ..where((tbl) => tbl.categoryId.equals(oldCat.id)))
            .get();

        for (final item in items) {
          final sub = item.subType.toLowerCase();
          final n = item.name.toLowerCase();
          int targetId = otherId;
          if (sub.contains('ppf') || n.contains('ppf')) {
            targetId = ppfId;
          } else if (sub.contains('epf') || n.contains('epf')) {
            targetId = epfId;
          } else if (sub.contains('gpf') || n.contains('gpf')) {
            targetId = gpfId;
          } else if (sub.contains('nps') || n.contains('nps')) {
            targetId = npsId;
          }

          await (update(financialItems)..where((tbl) => tbl.id.equals(item.id)))
              .write(FinancialItemsCompanion(categoryId: Value(targetId)));
        }

        // Archive old retirement category so it never appears in UI
        await (update(financialCategories)
              ..where((tbl) => tbl.id.equals(oldCat.id)))
            .write(const FinancialCategoriesCompanion(isArchived: Value(true)));
      }
    }
  }
}
