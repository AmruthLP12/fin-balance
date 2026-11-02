import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/core/scheduling/investment_schedule_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/database/precision/financial_precision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Investment Financial Accuracy & Isolation Tests', () {
    late AppDatabase db;
    late int profileId;
    const int schemeCode = 118989;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());

      profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Primary Investor'),
          relationship: drift.Value('self'),
          isDefault: drift.Value(true),
        ),
      );

      // Seed scheme
      await db.into(db.mutualFundSchemes).insert(
            MutualFundSchemesCompanion(
              schemeCode: const drift.Value(schemeCode),
              schemeName:
                  const drift.Value('HDFC Top 100 Fund - Direct Growth'),
              fundHouse: const drift.Value('HDFC Mutual Fund'),
              planType: const drift.Value('Direct'),
              optionType: const drift.Value('Growth'),
              latestNavMicroPaise:
                  drift.Value(FinancialPrecision.navToMicroPaise(100.0)),
              latestNavDate: drift.Value(DateTime.utc(2024, 6, 1)),
            ),
          );

      // Seed historical NAV: 100.0 on 2024-01-01, 100.0 on 2024-02-01
      for (final row in [
        NavHistoryCompanion(
          schemeCode: const drift.Value(schemeCode),
          navDate: drift.Value(DateTime.utc(2024, 1, 1)),
          navMicroPaise: drift.Value(FinancialPrecision.navToMicroPaise(100.0)),
        ),
        NavHistoryCompanion(
          schemeCode: const drift.Value(schemeCode),
          navDate: drift.Value(DateTime.utc(2024, 2, 1)),
          navMicroPaise: drift.Value(FinancialPrecision.navToMicroPaise(100.0)),
        ),
      ]) {
        await db.into(db.navHistory).insert(row);
      }
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'Schedule across past and future isolates planned capital from portfolio net worth',
        () async {
      // 5 monthly installments starting 2024-01-01 @ ₹1,000 per installment.
      // asOfDate = 2024-02-15.
      // Past occurrences: Jan 1 (₹1,000) and Feb 1 (₹1,000) -> ₹2,000.
      // Future occurrences: Mar 1 (₹1,000), Apr 1 (₹1,000), May 1 (₹1,000) -> ₹3,000 planned.
      final result = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: schemeCode,
        schemeName: 'HDFC Top 100 Fund',
        startDate: DateTime.utc(2024, 1, 1),
        totalInstallments: 5,
        frequency: ScheduleFrequency.monthly,
        amountPerInstallmentPaise: FinancialPrecision.rupeesToPaise(1000),
        markPastAsConfirmed: true,
        asOfDate: DateTime.utc(2024, 2, 15),
      );

      expect(result.pastInstallments, equals(2));
      expect(result.futureInstallments, equals(3));
      expect(result.confirmedInvestedPaise,
          equals(FinancialPrecision.rupeesToPaise(2000)));

      // Check the created holding in FinancialItems
      final holding =
          await db.financialItemsDao.getItemById(result.financialItemId);
      expect(holding, isNotNull);
      // Invested capital must reflect ONLY the 2 past confirmed installments (₹2,000)
      expect(holding!.initialValuePaise,
          equals(FinancialPrecision.rupeesToPaise(2000)));

      // Units: ₹1,000 / 100 NAV = 10 units each -> 20 units total = 20,000,000 microUnits
      expect(holding.unitCountMicroUnits, equals(20000000));

      // Current valuation at latest NAV (100.0) must be ₹2,000, NEVER ₹5,000
      expect(holding.currentValuationPaise,
          equals(FinancialPrecision.rupeesToPaise(2000)));

      // Verify transactions table has exactly 2 confirmed purchase records
      final txs = await (db.select(db.transactions)
            ..where(
                (tbl) => tbl.financialItemId.equals(result.financialItemId)))
          .get();
      expect(txs.length, equals(2));
    });

    test(
        'Multiple investment schedules for the same mutual fund scheme accumulate holding without overwriting',
        () async {
      // Schedule 1: 1 past installment of ₹1,000
      final res1 = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: schemeCode,
        schemeName: 'HDFC Top 100 Fund',
        startDate: DateTime.utc(2024, 1, 1),
        totalInstallments: 1,
        frequency: ScheduleFrequency.oneTime,
        amountPerInstallmentPaise: FinancialPrecision.rupeesToPaise(1000),
        markPastAsConfirmed: true,
        asOfDate: DateTime.utc(2024, 3, 1),
      );

      // Schedule 2: 1 past installment of ₹500
      final res2 = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: schemeCode,
        schemeName: 'HDFC Top 100 Fund',
        startDate: DateTime.utc(2024, 2, 1),
        totalInstallments: 1,
        frequency: ScheduleFrequency.oneTime,
        amountPerInstallmentPaise: FinancialPrecision.rupeesToPaise(500),
        markPastAsConfirmed: true,
        asOfDate: DateTime.utc(2024, 3, 1),
      );

      // Both schedules must link to the exact same holding
      expect(res1.financialItemId, equals(res2.financialItemId));

      final holding =
          await db.financialItemsDao.getItemById(res1.financialItemId);
      expect(holding, isNotNull);

      // Total invested = ₹1,000 + ₹500 = ₹1,500
      expect(holding!.initialValuePaise,
          equals(FinancialPrecision.rupeesToPaise(1500)));

      // Units = 10 units + 5 units = 15 units = 15,000,000 microUnits
      expect(holding.unitCountMicroUnits, equals(15000000));
    });

    test(
        'Simulated past installments do not create transactions or increment holding balance',
        () async {
      final result = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: schemeCode,
        schemeName: 'HDFC Top 100 Fund',
        startDate: DateTime.utc(2024, 1, 1),
        totalInstallments: 2,
        frequency: ScheduleFrequency.monthly,
        amountPerInstallmentPaise: FinancialPrecision.rupeesToPaise(1000),
        markPastAsConfirmed: false, // User requested estimate/simulation only
        asOfDate: DateTime.utc(2024, 3, 1),
      );

      expect(result.confirmedInvestedPaise, equals(0));
      expect(result.confirmedUnitsMicro, equals(0));

      final holding =
          await db.financialItemsDao.getItemById(result.financialItemId);
      expect(holding!.initialValuePaise, equals(0));
      expect(holding.unitCountMicroUnits, equals(0));

      final txs = await (db.select(db.transactions)
            ..where(
                (tbl) => tbl.financialItemId.equals(result.financialItemId)))
          .get();
      expect(txs, isEmpty);
    });
  });
}
