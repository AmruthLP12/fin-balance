import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/core/scheduling/recurring_date_calculator.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('RecurringDateCalculator & Date Handling Tests', () {
    test('Clamps 31st to 28/29th Feb and 30th Apr without drift', () {
      // Leap year 2024
      expect(RecurringDateCalculator.daysInMonth(2024, 2), equals(29));
      expect(RecurringDateCalculator.clampDay(2024, 2, 31), equals(29));
      expect(RecurringDateCalculator.clampDay(2024, 2, 15), equals(15));

      // Standard year 2025
      expect(RecurringDateCalculator.daysInMonth(2025, 2), equals(28));
      expect(RecurringDateCalculator.clampDay(2025, 2, 31), equals(28));

      // 30-day month
      expect(RecurringDateCalculator.daysInMonth(2024, 4), equals(30));
      expect(RecurringDateCalculator.clampDay(2024, 4, 31), equals(30));

      // 31-day month
      expect(RecurringDateCalculator.daysInMonth(2024, 1), equals(31));
      expect(RecurringDateCalculator.clampDay(2024, 1, 31), equals(31));
    });

    test('generateMonthlyOccurrences preserves original day and does not drift',
        () {
      final dates = RecurringDateCalculator.generateMonthlyOccurrences(
        fromDate: DateTime.utc(2024, 1, 15),
        toDate: DateTime.utc(2024, 5, 31),
        configuredDay: 31,
      );

      // January: 31st
      // February: 29th (2024 is leap year)
      // March: 31st (returned to 31!)
      // April: 30th
      // May: 31st
      expect(dates.length, equals(5));
      expect(dates[0], equals(DateTime.utc(2024, 1, 31)));
      expect(dates[1], equals(DateTime.utc(2024, 2, 29)));
      expect(dates[2], equals(DateTime.utc(2024, 3, 31)));
      expect(dates[3], equals(DateTime.utc(2024, 4, 30)));
      expect(dates[4], equals(DateTime.utc(2024, 5, 31)));
    });
  });

  group('Flexible SIP Database & Schedule Period Tests', () {
    late AppDatabase db;
    late int profileId;
    const schemeCode = 125497;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());

      // Create test profile
      profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Investor A'),
          relationship: drift.Value('Self'),
        ),
      );

      // Upsert scheme
      await db.mutualFundDao.upsertScheme(
        const MutualFundSchemesCompanion(
          schemeCode: drift.Value(schemeCode),
          schemeName: drift.Value('Parag Parikh Flexi Cap Fund'),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'Creates master SIP with initial schedule period and auto-generates installments',
        () async {
      final sipId = await db.sipsDao.createSipWithPeriod(
        profileId: profileId,
        schemeCode: schemeCode,
        name: 'My Flexi Cap SIP',
        startDate: DateTime.utc(2024, 1, 1),
        endDate: DateTime.utc(2024, 4, 30),
        amountPaise: 10000, // ₹100
        deductionDay: 3,
      );

      final periods = await db.sipsDao.getSchedulePeriods(sipId);
      expect(periods.length, equals(1));
      expect(periods.first.amountPaise, equals(10000));
      expect(periods.first.deductionDay, equals(3));

      final installments = await db.sipsDao.getInstallments(sipId);
      expect(installments.length, equals(4)); // Jan, Feb, Mar, Apr
      expect(
          installments[0]
              .scheduledDate
              .isAtSameMomentAs(DateTime.utc(2024, 1, 3)),
          isTrue);
      expect(
          installments[1]
              .scheduledDate
              .isAtSameMomentAs(DateTime.utc(2024, 2, 3)),
          isTrue);
      expect(
          installments[2]
              .scheduledDate
              .isAtSameMomentAs(DateTime.utc(2024, 3, 3)),
          isTrue);
      expect(
          installments[3]
              .scheduledDate
              .isAtSameMomentAs(DateTime.utc(2024, 4, 3)),
          isTrue);
    });

    test(
        'Flexible SIP: adds new schedule period with different amount and deduction date without drift',
        () async {
      // 1. Initial period: Jan 2024 to Apr 2024 at ₹100 on 3rd
      final sipId = await db.sipsDao.createSipWithPeriod(
        profileId: profileId,
        schemeCode: schemeCode,
        name: 'Flexible SIP',
        startDate: DateTime.utc(2024, 1, 1),
        endDate: DateTime.utc(2024, 12, 31),
        amountPaise: 10000, // ₹100
        deductionDay: 3,
      );

      // 2. Add second period starting May 2024: amount increased to ₹500, deduction day changed to 5th
      final period2Id = await db.sipsDao.addSchedulePeriod(
        sipPlanId: sipId,
        effectiveFrom: DateTime.utc(2024, 5, 1),
        amountPaise: 50000, // ₹500
        deductionDay: 5,
        notes: 'Increased SIP amount to 500',
      );

      expect(period2Id, isPositive);

      final periods = await db.sipsDao.getSchedulePeriods(sipId);
      expect(periods.length, equals(2));
      expect(periods[0].effectiveTo, isNotNull);
      expect(
          periods[0].effectiveTo!.isBefore(DateTime.utc(2024, 5, 1)), isTrue);
      expect(periods[1].amountPaise, equals(50000));
      expect(periods[1].deductionDay, equals(5));

      // 3. Add third period starting Sep 2024: amount reduced to ₹200, day changed to 7th
      final period3Id = await db.sipsDao.addSchedulePeriod(
        sipPlanId: sipId,
        effectiveFrom: DateTime.utc(2024, 9, 1),
        amountPaise: 20000, // ₹200
        deductionDay: 7,
        notes: 'Reduced SIP amount to 200',
      );

      expect(period3Id, isPositive);
      final updatedPeriods = await db.sipsDao.getSchedulePeriods(sipId);
      expect(updatedPeriods.length, equals(3));
      expect(updatedPeriods[2].amountPaise, equals(20000));
      expect(updatedPeriods[2].deductionDay, equals(7));
    });

    test(
        'Bulk historical SIP entry generates all intermediate monthly installments',
        () async {
      final sipId = await db.sipsDao.recordBulkHistoricalSip(
        profileId: profileId,
        schemeCode: schemeCode,
        name: 'Bulk Past SIP',
        fromDate: DateTime.utc(2024, 1, 1),
        toDate: DateTime.utc(2024, 6, 30),
        amountPaise: 250000, // ₹2,500
        deductionDay: 10,
        markAsConfirmed: true,
      );

      final installments = await db.sipsDao.getInstallments(sipId);
      expect(installments.length, equals(6)); // Jan to June
      for (final inst in installments) {
        expect(inst.status, equals('recorded'));
        expect(inst.isSimulated, isFalse);
        expect(inst.actualAmountPaise, equals(250000));
        expect(inst.scheduledDate.day, equals(10));
      }

      // Check that corresponding transactions were recorded
      final txns =
          await db.transactionsDao.getRecentTransactionsForProfile(profileId);
      expect(txns.length, equals(6));
    });

    test(
        'Bulk historical SIP entry with simulated=true does not inflate actual ledger transactions',
        () async {
      final initialTxns =
          await db.transactionsDao.getRecentTransactionsForProfile(profileId);
      expect(initialTxns.length, equals(0));

      final sipId = await db.sipsDao.recordBulkHistoricalSip(
        profileId: profileId,
        schemeCode: schemeCode,
        name: 'Simulated Historical Projections',
        fromDate: DateTime.utc(2024, 1, 1),
        toDate: DateTime.utc(2024, 5, 31),
        amountPaise: 500000, // ₹5,000
        deductionDay: 15,
        markAsConfirmed: false,
      );

      final installments = await db.sipsDao.getInstallments(sipId);
      expect(installments.length, equals(5));
      for (final inst in installments) {
        expect(inst.isSimulated, isTrue);
        expect(inst.status, equals('simulated'));
      }

      // Real transactions must remain 0
      final txns =
          await db.transactionsDao.getRecentTransactionsForProfile(profileId);
      expect(txns.length, equals(0));
    });

    test(
        'Installment duplicate prevention guarantees no duplicate records for same date',
        () async {
      final sipId = await db.sipsDao.createSipWithPeriod(
        profileId: profileId,
        schemeCode: schemeCode,
        name: 'Duplicate Guard SIP',
        startDate: DateTime.utc(2024, 1, 1),
        endDate: DateTime.utc(2024, 2, 28),
        amountPaise: 10000,
        deductionDay: 10,
      );

      final countBefore = (await db.sipsDao.getInstallments(sipId)).length;
      expect(countBefore, equals(2));

      // Attempt to re-insert identical installment manually
      await db.into(db.sipInstallments).insert(
            SipInstallmentsCompanion(
              sipPlanId: drift.Value(sipId),
              schedulePeriodId: const drift.Value(1),
              profileId: drift.Value(profileId),
              scheduledDate: drift.Value(DateTime.utc(2024, 1, 10)),
              expectedAmountPaise: const drift.Value(10000),
              status: const drift.Value('upcoming'),
              isSimulated: const drift.Value(true),
            ),
            onConflict: drift.DoNothing(
              target: [
                db.sipInstallments.sipPlanId,
                db.sipInstallments.scheduledDate
              ],
            ),
          );

      final countAfter = (await db.sipsDao.getInstallments(sipId)).length;
      expect(countAfter, equals(2)); // No duplicates inserted
    });

    test(
        'Records actual installment, calculates units from NAV, and logs transaction',
        () async {
      final sipId = await db.sipsDao.createSipWithPeriod(
        profileId: profileId,
        schemeCode: schemeCode,
        name: 'Actual Logging SIP',
        startDate: DateTime.utc(2024, 1, 1),
        endDate: DateTime.utc(2024, 1, 31),
        amountPaise: 100000, // ₹1,000
        deductionDay: 5,
      );

      final installments = await db.sipsDao.getInstallments(sipId);
      expect(installments.length, equals(1));
      final inst = installments.first;

      final success = await db.sipsDao.recordActualInstallment(
        installmentId: inst.id,
        actualDate: DateTime.utc(2024, 1, 5),
        actualAmountPaise: 100000,
        purchaseNavMicroPaise: 50000000, // ₹50 NAV
      );

      expect(success, isTrue);

      final updated = (await db.sipsDao.getInstallments(sipId)).first;
      expect(updated.status, equals('recorded'));
      expect(updated.isSimulated, isFalse);
      expect(updated.purchaseNavMicroPaise, equals(50000000));
      // 1000 / 50 = 20 units -> 20,000,000 micro units
      expect(updated.unitsMicroUnits, equals(20000000));
      expect(updated.transactionId, isNotNull);
    });

    test('Skips upcoming installment correctly', () async {
      final sipId = await db.sipsDao.createSipWithPeriod(
        profileId: profileId,
        schemeCode: schemeCode,
        name: 'Skip Test SIP',
        startDate: DateTime.utc(2024, 1, 1),
        endDate: DateTime.utc(2024, 1, 31),
        amountPaise: 100000,
        deductionDay: 5,
      );

      final inst = (await db.sipsDao.getInstallments(sipId)).first;
      await db.sipsDao.skipInstallment(inst.id);

      final updated = (await db.sipsDao.getInstallments(sipId)).first;
      expect(updated.status, equals('skipped'));
    });
  });
}
