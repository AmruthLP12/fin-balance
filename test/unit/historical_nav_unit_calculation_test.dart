import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/core/scheduling/investment_schedule_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/database/precision/financial_precision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Historical NAV & Unit Calculation Tests', () {
    late AppDatabase db;
    late int profileId;
    const int schemeCode = 120503;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());

      // Seed profile
      profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Test Investor'),
          relationship: drift.Value('self'),
          isDefault: drift.Value(true),
        ),
      );

      // Seed scheme metadata
      await db.into(db.mutualFundSchemes).insert(
            MutualFundSchemesCompanion(
              schemeCode: const drift.Value(schemeCode),
              schemeName:
                  const drift.Value('Axis Bluechip Fund - Direct Growth'),
              fundHouse: const drift.Value('Axis Mutual Fund'),
              planType: const drift.Value('Direct'),
              optionType: const drift.Value('Growth'),
              latestNavMicroPaise:
                  drift.Value(FinancialPrecision.navToMicroPaise(50.0)),
              latestNavDate: drift.Value(DateTime.utc(2024, 4, 15)),
            ),
          );

      // Seed historical NAVs:
      // Friday, Jan 5, 2024: 40.00
      // Monday, Jan 8, 2024: 41.00
      // Tuesday, Jan 9, 2024: Market Holiday (no NAV)
      // Wednesday, Jan 10, 2024: 42.50
      for (final row in [
        NavHistoryCompanion(
          schemeCode: const drift.Value(schemeCode),
          navDate: drift.Value(DateTime.utc(2024, 1, 5)),
          navMicroPaise: drift.Value(FinancialPrecision.navToMicroPaise(40.0)),
        ),
        NavHistoryCompanion(
          schemeCode: const drift.Value(schemeCode),
          navDate: drift.Value(DateTime.utc(2024, 1, 8)),
          navMicroPaise: drift.Value(FinancialPrecision.navToMicroPaise(41.0)),
        ),
        NavHistoryCompanion(
          schemeCode: const drift.Value(schemeCode),
          navDate: drift.Value(DateTime.utc(2024, 1, 10)),
          navMicroPaise: drift.Value(FinancialPrecision.navToMicroPaise(42.5)),
        ),
      ]) {
        await db.into(db.navHistory).insert(row);
      }
    });

    tearDown(() async {
      await db.close();
    });

    test('Exact date NAV match retrieves exact record', () async {
      final nav = await db.mutualFundDao
          .getNavOnOrBefore(schemeCode, DateTime.utc(2024, 1, 8));
      expect(nav, isNotNull);
      expect(
          nav!.navMicroPaise, equals(FinancialPrecision.navToMicroPaise(41.0)));
      expect(nav.navDate.year, equals(2024));
      expect(nav.navDate.month, equals(1));
      expect(nav.navDate.day, equals(8));
    });

    test('Weekend fallback picks up latest preceding business day NAV',
        () async {
      // Saturday, Jan 6, 2024 -> should fall back to Friday Jan 5 (NAV 40.0)
      final saturdayNav = await db.mutualFundDao
          .getNavOnOrBefore(schemeCode, DateTime.utc(2024, 1, 6));
      expect(saturdayNav, isNotNull);
      expect(saturdayNav!.navMicroPaise,
          equals(FinancialPrecision.navToMicroPaise(40.0)));
      expect(saturdayNav.navDate.year, equals(2024));
      expect(saturdayNav.navDate.month, equals(1));
      expect(saturdayNav.navDate.day, equals(5));

      // Sunday, Jan 7, 2024 -> should also fall back to Friday Jan 5 (NAV 40.0)
      final sundayNav = await db.mutualFundDao
          .getNavOnOrBefore(schemeCode, DateTime.utc(2024, 1, 7));
      expect(sundayNav, isNotNull);
      expect(sundayNav!.navMicroPaise,
          equals(FinancialPrecision.navToMicroPaise(40.0)));
      expect(sundayNav.navDate.year, equals(2024));
      expect(sundayNav.navDate.month, equals(1));
      expect(sundayNav.navDate.day, equals(5));
    });

    test('Market holiday fallback picks up previous trading day NAV', () async {
      // Tuesday, Jan 9, 2024 is a holiday without NAV -> should fall back to Monday Jan 8 (NAV 41.0)
      final holidayNav = await db.mutualFundDao
          .getNavOnOrBefore(schemeCode, DateTime.utc(2024, 1, 9));
      expect(holidayNav, isNotNull);
      expect(holidayNav!.navMicroPaise,
          equals(FinancialPrecision.navToMicroPaise(41.0)));
      expect(holidayNav.navDate.year, equals(2024));
      expect(holidayNav.navDate.month, equals(1));
      expect(holidayNav.navDate.day, equals(8));
    });

    test(
        'Missing NAV marks installment as pending_valuation without inventing fake NAV',
        () async {
      // Create a schedule starting in Dec 2023 where we have NO NAVs at all
      final result = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: schemeCode,
        schemeName: 'Axis Bluechip Fund',
        startDate: DateTime.utc(2023, 12, 1),
        totalInstallments: 1,
        frequency: ScheduleFrequency.oneTime,
        amountPerInstallmentPaise: FinancialPrecision.rupeesToPaise(1000),
        asOfDate: DateTime.utc(2024, 2, 1), // Dec 1 is in the past
      );

      expect(result.pendingValuationCount, equals(1));
      expect(result.valuedPastCount, equals(0));

      final installments = await db.sipsDao.getInstallments(result.sipPlanId);
      expect(installments.length, equals(1));
      expect(installments.first.status, equals('pending_valuation'));
      expect(installments.first.purchaseNavMicroPaise, isNull);
      expect(installments.first.unitsMicroUnits, isNull);

      // Verify that revaluePendingInstallments recovers once historical NAV is added
      await db.into(db.navHistory).insert(
            NavHistoryCompanion(
              schemeCode: const drift.Value(schemeCode),
              navDate: drift.Value(DateTime.utc(2023, 12, 1)),
              navMicroPaise:
                  drift.Value(FinancialPrecision.navToMicroPaise(38.0)),
            ),
          );

      final revaluedCount =
          await db.sipsDao.revaluePendingInstallments(schemeCode);
      expect(revaluedCount, equals(1));

      final updatedInstallment =
          (await db.sipsDao.getInstallments(result.sipPlanId)).first;
      expect(updatedInstallment.status, equals('recorded'));
      expect(updatedInstallment.purchaseNavMicroPaise,
          equals(FinancialPrecision.navToMicroPaise(38.0)));
      expect(updatedInstallment.unitsMicroUnits, isNotNull);
    });

    test('Future installments never calculate units with current NAV',
        () async {
      final asOf = DateTime.utc(2024, 1, 1);
      final result = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: schemeCode,
        schemeName: 'Axis Bluechip Fund',
        startDate: DateTime.utc(2024, 2, 1), // In the future relative to asOf
        totalInstallments: 3,
        frequency: ScheduleFrequency.monthly,
        amountPerInstallmentPaise: FinancialPrecision.rupeesToPaise(500),
        asOfDate: asOf,
      );

      expect(result.pastInstallments, equals(0));
      expect(result.futureInstallments, equals(3));
      expect(result.confirmedInvestedPaise, equals(0));
      expect(result.confirmedUnitsMicro, equals(0));

      final installments = await db.sipsDao.getInstallments(result.sipPlanId);
      expect(installments.length, equals(3));
      for (final inst in installments) {
        expect(inst.status, equals('upcoming'));
        expect(inst.isSimulated, isTrue);
        expect(inst.purchaseNavMicroPaise, isNull);
        expect(inst.unitsMicroUnits, isNull);
      }
    });

    test('Precision: Micro-units purchased preserves integer accuracy', () {
      // 500 rupees = 50,000 paise
      // NAV = 40.00 -> 40,000,000 microPaise
      // Expected units = 500 / 40 = 12.5 units = 12,500,000 microUnits
      final unitsMicro = FinancialPrecision.calculateUnitsPurchased(
        amountPaise: 50000,
        navMicroPaise: 40000000,
      );
      expect(unitsMicro, equals(12500000));
      expect(FinancialPrecision.microUnitsToUnits(unitsMicro), equals(12.5));
    });
  });
}
