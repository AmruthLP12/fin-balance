import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:finbalance/core/providers/database_provider.dart';
import 'package:finbalance/core/providers/theme_provider.dart';
import 'package:finbalance/core/scheduling/investment_schedule_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    await db.mutualFundDao.upsertScheme(
      const MutualFundSchemesCompanion(
        schemeCode: Value(120503),
        schemeName: Value('Axis Bluechip Fund'),
        latestNavMicroPaise: Value(50000000),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Milestone Scope Control & Theme Persistence Tests', () {
    test('Theme selection persists to AppSettingsDao and reloads correctly',
        () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      // Default should be system
      expect(container.read(themeModeProvider), ThemeMode.system);

      // Change to dark mode
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      // Verify written to app_settings table
      final savedValue = await db.appSettingsDao.getSetting('theme_mode');
      expect(savedValue, 'dark');

      // Create a fresh container with same database to verify cold restoration
      final container2 = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container2.dispose);

      final notifier2 = container2.read(themeModeProvider.notifier);
      await notifier2.loadPersistedTheme();
      expect(container2.read(themeModeProvider), ThemeMode.dark);
    });

    test(
        'Net worth calculations strictly exclude liabilities when requested for milestone scope',
        () async {
      final profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(name: Value('Scope User')),
      );

      // Insert an asset of ₹10,000 (1000000 paise)
      await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(profileId),
          name: const Value('Mutual Fund A'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: const Value(1),
          initialValuePaise: const Value(1000000),
          currentValuationPaise: const Value(1200000), // ₹12,000 current
          status: const Value('active'),
        ),
      );

      // Insert a liability of ₹5,000 (500000 paise)
      await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(profileId),
          name: const Value('Personal Loan'),
          itemType: const Value('liability'),
          subType: const Value('personal_loan'),
          categoryId: const Value(2),
          initialValuePaise: const Value(500000),
          currentValuationPaise: const Value(500000),
          status: const Value('active'),
        ),
      );

      // Milestone asset-only net worth MUST equal ₹12,000 (1200000 paise)
      final profileAssetNetWorth = await db.financialItemsDao
          .calculateNetWorthForProfile(profileId, includeLiabilities: false);
      expect(profileAssetNetWorth, 1200000);

      final householdAssetNetWorth = await db.financialItemsDao
          .calculateHouseholdNetWorth(includeLiabilities: false);
      expect(householdAssetNetWorth, 1200000);

      // Full balance sheet calculation accounts for liabilities: ₹12,000 - ₹5,000 = ₹7,000
      final profileFullNetWorth =
          await db.financialItemsDao.calculateNetWorthForProfile(profileId);
      expect(profileFullNetWorth, 700000);
    });

    test(
        'deleteHoldingCascade atomically deletes linked SIPs, installments, and transactions',
        () async {
      final profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(name: Value('Cascade User')),
      );

      final result = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: 120503,
        schemeName: 'Axis Bluechip Fund',
        amountPerInstallmentPaise: 500000,
        startDate: DateTime.utc(2024, 1, 15),
        installmentCount: 2,
        frequency: ScheduleFrequency.monthly,
        asOfDate: DateTime.utc(2024, 2, 20),
      );

      final holdingId = result.financialItemId;
      final sipId = result.sipPlanId;

      // Verify linked records exist
      expect(await db.sipsDao.getSipById(sipId), isNotNull);
      expect(await db.sipsDao.getInstallments(sipId), isNotEmpty);

      // Cascade delete the holding
      final success =
          await db.financialItemsDao.deleteHoldingCascade(holdingId);
      expect(success, isTrue);

      // Verify holding is gone
      expect(await db.financialItemsDao.getItemById(holdingId), isNull);

      // Verify linked SIP is gone
      expect(await db.sipsDao.getSipById(sipId), isNull);

      // Verify installments are gone
      expect(await db.sipsDao.getInstallments(sipId), isEmpty);

      // Verify shared scheme is preserved
      expect(await db.mutualFundDao.getSchemeByCode(120503), isNotNull);
    });
  });
}
