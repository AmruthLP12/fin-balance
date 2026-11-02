import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/core/scheduling/investment_schedule_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/database/precision/financial_precision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Schedule Editing & Historical Preservation Tests', () {
    late AppDatabase db;
    late int profileId;
    const int schemeCode = 125497;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());

      profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Schedule Editor'),
          relationship: drift.Value('self'),
          isDefault: drift.Value(true),
        ),
      );

      // Seed scheme & historical NAVs
      await db.into(db.mutualFundSchemes).insert(
            MutualFundSchemesCompanion(
              schemeCode: const drift.Value(schemeCode),
              schemeName:
                  const drift.Value('SBI Bluechip Fund - Direct Growth'),
              fundHouse: const drift.Value('SBI Mutual Fund'),
              planType: const drift.Value('Direct'),
              optionType: const drift.Value('Growth'),
              latestNavMicroPaise:
                  drift.Value(FinancialPrecision.navToMicroPaise(80.0)),
              latestNavDate: drift.Value(DateTime.utc(2024, 6, 1)),
            ),
          );

      for (final row in [
        NavHistoryCompanion(
          schemeCode: const drift.Value(schemeCode),
          navDate: drift.Value(DateTime.utc(2024, 1, 1)),
          navMicroPaise: drift.Value(FinancialPrecision.navToMicroPaise(80.0)),
        ),
        NavHistoryCompanion(
          schemeCode: const drift.Value(schemeCode),
          navDate: drift.Value(DateTime.utc(2024, 2, 1)),
          navMicroPaise: drift.Value(FinancialPrecision.navToMicroPaise(80.0)),
        ),
      ]) {
        await db.into(db.navHistory).insert(row);
      }
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'updateInvestmentSchedule modifies only future installments and strictly preserves past records',
        () async {
      // 1. Create original schedule: 4 monthly installments starting 2024-01-01 of ₹500
      // As of 2024-02-15:
      // Installment 1: Jan 1 (Past, Confirmed, ₹500, NAV 80)
      // Installment 2: Feb 1 (Past, Confirmed, ₹500, NAV 80)
      // Installment 3: Mar 1 (Future, Upcoming, ₹500)
      // Installment 4: Apr 1 (Future, Upcoming, ₹500)
      final initialResult = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: schemeCode,
        schemeName: 'SBI Bluechip Fund',
        startDate: DateTime.utc(2024, 1, 1),
        totalInstallments: 4,
        frequency: ScheduleFrequency.monthly,
        amountPerInstallmentPaise: FinancialPrecision.rupeesToPaise(500),
        markPastAsConfirmed: true,
        asOfDate: DateTime.utc(2024, 2, 15),
      );

      final initialInstallments =
          await db.sipsDao.getInstallmentsByPlan(initialResult.sipPlanId);
      expect(initialInstallments.length, equals(4));

      final pastBefore =
          initialInstallments.where((i) => i.status == 'recorded').toList();
      expect(pastBefore.length, equals(2));
      final pastTxIds = pastBefore.map((i) => i.transactionId).toList();

      // 2. Now user modifies schedule with effective date: March 1, 2024
      // Increase amount from ₹500 to ₹1,500, switch to weekly frequency, 3 remaining installments
      final updateSuccess = await db.sipsDao.updateInvestmentSchedule(
        sipPlanId: initialResult.sipPlanId,
        effectiveDate: DateTime.utc(2024, 3, 1),
        newAmountPaise: FinancialPrecision.rupeesToPaise(1500),
        newFrequency: ScheduleFrequency.weekly,
        remainingInstallments: 3,
        notes: 'Stepped up SIP weekly from March',
      );

      expect(updateSuccess, isTrue);

      // 3. Inspect updated installments
      final updatedInstallments =
          await db.sipsDao.getInstallmentsByPlan(initialResult.sipPlanId);

      // Past installments must STILL exist, with identical recorded status and transaction IDs!
      final pastAfter =
          updatedInstallments.where((i) => i.status == 'recorded').toList();
      expect(pastAfter.length, equals(2));
      expect(pastAfter[0].scheduledDate.year, equals(2024));
      expect(pastAfter[0].scheduledDate.month, equals(1));
      expect(pastAfter[0].scheduledDate.day, equals(1));
      expect(pastAfter[0].expectedAmountPaise,
          equals(FinancialPrecision.rupeesToPaise(500)));
      expect(pastAfter[0].transactionId, equals(pastTxIds[0]));

      expect(pastAfter[1].scheduledDate.year, equals(2024));
      expect(pastAfter[1].scheduledDate.month, equals(2));
      expect(pastAfter[1].scheduledDate.day, equals(1));
      expect(pastAfter[1].expectedAmountPaise,
          equals(FinancialPrecision.rupeesToPaise(500)));
      expect(pastAfter[1].transactionId, equals(pastTxIds[1]));

      // Future installments must reflect the new weekly schedule of ₹1,500
      final futureAfter =
          updatedInstallments.where((i) => i.status == 'upcoming').toList();
      expect(futureAfter.length, equals(3));
      for (final f in futureAfter) {
        expect(f.expectedAmountPaise,
            equals(FinancialPrecision.rupeesToPaise(1500)));
        expect(f.isSimulated, isTrue);
      }
      expect(futureAfter[0].scheduledDate.year, equals(2024));
      expect(futureAfter[0].scheduledDate.month, equals(3));
      expect(futureAfter[0].scheduledDate.day, equals(1));

      expect(futureAfter[1].scheduledDate.year, equals(2024));
      expect(futureAfter[1].scheduledDate.month, equals(3));
      expect(futureAfter[1].scheduledDate.day, equals(8));

      expect(futureAfter[2].scheduledDate.year, equals(2024));
      expect(futureAfter[2].scheduledDate.month, equals(3));
      expect(futureAfter[2].scheduledDate.day, equals(15));

      // Holding invested balance and units must remain untouched
      final holding =
          await db.financialItemsDao.getItemById(initialResult.financialItemId);
      expect(holding!.initialValuePaise,
          equals(FinancialPrecision.rupeesToPaise(1000)));
    });
  });
}
