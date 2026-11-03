import 'package:drift/drift.dart';
import '../app_database.dart';
import '../precision/financial_precision.dart';
import '../tables/transactions.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  /// Watch recent transactions for a specific profile.
  Stream<List<Transaction>> watchRecentTransactionsForProfile(
    int profileId, {
    int limit = 50,
  }) {
    return (select(transactions)
          ..where((tbl) => tbl.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(limit))
        .watch();
  }

  /// Get recent transactions for a specific profile.
  Future<List<Transaction>> getRecentTransactionsForProfile(
    int profileId, {
    int limit = 50,
  }) {
    return (select(transactions)
          ..where((tbl) => tbl.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(limit))
        .get();
  }

  /// Get paginated transactions for a specific profile for bounded lazy-loading.
  Future<List<Transaction>> getPaginatedTransactionsForProfile(
    int profileId, {
    int limit = 20,
    int offset = 0,
  }) {
    return (select(transactions)
          ..where((tbl) => tbl.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Watch household recent transactions across all profiles.
  Stream<List<Transaction>> watchHouseholdRecentTransactions({int limit = 50}) {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(limit))
        .watch();
  }

  /// Get transactions for a specific profile and item.
  Future<List<Transaction>> getTransactionsByItem(
    int profileId,
    int financialItemId,
  ) {
    return (select(transactions)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
        .get();
  }

  /// Get the earliest / primary investment purchase transaction for a financial item.
  Future<Transaction?> getPrimaryTransactionForItem(
    int profileId,
    int financialItemId,
  ) {
    return (select(transactions)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Watch transactions for a specific profile and item.
  Stream<List<Transaction>> watchTransactionsByItem(
    int profileId,
    int financialItemId,
  ) {
    return (select(transactions)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  /// Get transactions by date range for a specific profile.
  Future<List<Transaction>> getTransactionsByDateRange(
    int profileId,
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.transactionDate.isBiggerOrEqualValue(start) &
              tbl.transactionDate.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
        .get();
  }

  /// Get transaction by ID.
  Future<Transaction?> getTransactionById(int id) {
    return (select(transactions)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Validate cross-profile relationship integrity.
  /// Throws [ArgumentError] if the transaction references an account or item from a different profile.
  Future<void> validateProfileIntegrity(
      TransactionsCompanion transaction) async {
    final profileId = transaction.profileId.value;

    // Check financial item ownership
    if (transaction.financialItemId.present &&
        transaction.financialItemId.value != null) {
      final item = await db.financialItemsDao
          .getItemById(transaction.financialItemId.value!);
      if (item != null && item.profileId != profileId) {
        throw ArgumentError(
            'Cross-profile violation: Financial item ${item.id} belongs to profile ${item.profileId}, but transaction belongs to profile $profileId.');
      }
    }

    // Check fromAccount ownership
    if (transaction.fromAccountId.present &&
        transaction.fromAccountId.value != null) {
      final account =
          await db.accountsDao.getAccountById(transaction.fromAccountId.value!);
      if (account != null && account.profileId != profileId) {
        throw ArgumentError(
            'Cross-profile violation: Account ${account.id} belongs to profile ${account.profileId}, but transaction belongs to profile $profileId.');
      }
    }

    // Check toAccount ownership
    if (transaction.toAccountId.present &&
        transaction.toAccountId.value != null) {
      final account =
          await db.accountsDao.getAccountById(transaction.toAccountId.value!);
      if (account != null && account.profileId != profileId) {
        throw ArgumentError(
            'Cross-profile violation: Account ${account.id} belongs to profile ${account.profileId}, but transaction belongs to profile $profileId.');
      }
    }
  }

  /// Insert a new transaction with profile integrity enforcement.
  Future<int> insertTransaction(TransactionsCompanion transaction) async {
    await validateProfileIntegrity(transaction);
    return into(transactions).insert(transaction);
  }

  /// Update a transaction.
  Future<bool> updateTransaction(Transaction transaction) {
    return update(transactions).replace(transaction);
  }

  /// Delete a transaction.
  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Record an investment transaction with atomic unit, valuation, and cost basis updates.
  Future<int> recordInvestmentTransaction({
    required int profileId,
    required int financialItemId,
    required int categoryId,
    required String transactionType,
    required DateTime transactionDate,
    required int amountPaise,
    int chargesPaise = 0,
    int? unitsMicroUnits,
    int? unitPriceMicroPaise,
    int? sipPlanId,
    int? swpPlanId,
    int? linkedTransactionId,
    String? notes,
    String source = 'manual',
  }) async {
    return transaction(() async {
      final holding = await db.financialItemsDao.getItemById(financialItemId);
      if (holding == null) {
        throw ArgumentError('Financial item $financialItemId does not exist.');
      }
      if (holding.profileId != profileId) {
        throw ArgumentError(
            'Cross-profile violation for item $financialItemId.');
      }

      final type = transactionType.toLowerCase();
      int? netAmount;
      if (type == 'investment_purchase' ||
          type == 'sip_investment' ||
          type == 'switch_in') {
        netAmount = amountPaise + chargesPaise;
      } else if (type == 'redemption' ||
          type == 'swp_withdrawal' ||
          type == 'switch_out' ||
          type == 'dividend_payout') {
        netAmount = amountPaise - chargesPaise;
      } else if (type == 'dividend_reinvestment') {
        netAmount = 0;
      } else {
        netAmount = amountPaise;
      }

      // Check redemption/SWP units constraint
      if (type == 'redemption' ||
          type == 'swp_withdrawal' ||
          type == 'switch_out') {
        final unitsToDeduct = unitsMicroUnits ?? 0;
        if (unitsToDeduct > holding.unitCountMicroUnits) {
          throw ArgumentError(
            'Cannot redeem more units than available. Available: ${FinancialPrecision.microUnitsToUnits(holding.unitCountMicroUnits)}, requested: ${FinancialPrecision.microUnitsToUnits(unitsToDeduct)}',
          );
        }
      }

      // 1. Insert transaction
      final txId = await into(transactions).insert(
        TransactionsCompanion(
          profileId: Value(profileId),
          categoryId: Value(categoryId),
          financialItemId: Value(financialItemId),
          transactionType: Value(transactionType),
          transactionDate: Value(transactionDate),
          amountPaise: Value(amountPaise),
          chargesPaise: Value(chargesPaise),
          netAmountPaise: Value(netAmount),
          unitsMicroUnits: unitsMicroUnits != null
              ? Value(unitsMicroUnits)
              : const Value.absent(),
          unitPriceMicroPaise: unitPriceMicroPaise != null
              ? Value(unitPriceMicroPaise)
              : const Value.absent(),
          sipPlanId:
              sipPlanId != null ? Value(sipPlanId) : const Value.absent(),
          swpPlanId:
              swpPlanId != null ? Value(swpPlanId) : const Value.absent(),
          linkedTransactionId: linkedTransactionId != null
              ? Value(linkedTransactionId)
              : const Value.absent(),
          source: Value(source),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ),
      );

      // 2. Update holding units & cost basis
      int newUnits = holding.unitCountMicroUnits;
      int newInvested = holding.initialValuePaise;

      if (type == 'investment_purchase' ||
          type == 'sip_investment' ||
          type == 'switch_in') {
        newUnits += (unitsMicroUnits ?? 0);
        newInvested += (amountPaise + chargesPaise);
      } else if (type == 'dividend_reinvestment') {
        newUnits += (unitsMicroUnits ?? 0);
        // External cash invested remains unchanged
      } else if (type == 'dividend_payout') {
        // Cash payout does not alter units held
      } else if (type == 'redemption' ||
          type == 'swp_withdrawal' ||
          type == 'switch_out') {
        final unitsDeducted = unitsMicroUnits ?? 0;
        if (holding.unitCountMicroUnits > 0 && unitsDeducted > 0) {
          final costReduction = (holding.initialValuePaise *
                  (unitsDeducted / holding.unitCountMicroUnits))
              .round();
          newInvested = (holding.initialValuePaise - costReduction)
              .clamp(0, double.maxFinite.toInt());
        } else {
          newInvested = (holding.initialValuePaise - amountPaise)
              .clamp(0, double.maxFinite.toInt());
        }
        newUnits = (holding.unitCountMicroUnits - unitsDeducted)
            .clamp(0, double.maxFinite.toInt());
      }

      // Recalculate valuation
      int latestNav = unitPriceMicroPaise ?? 100000000;
      final schemeCode = int.tryParse(holding.externalCode ?? '');
      if (schemeCode != null && schemeCode > 0) {
        final scheme = await db.mutualFundDao.getSchemeByCode(schemeCode);
        if (scheme != null &&
            scheme.latestNavMicroPaise != null &&
            scheme.latestNavMicroPaise! > 0) {
          latestNav = scheme.latestNavMicroPaise!;
        }
      }

      final newValuation = FinancialPrecision.calculateValuationPaise(
        unitCountMicroUnits: newUnits,
        navMicroPaise: latestNav,
      );

      await db.financialItemsDao.updateItem(
        holding.copyWith(
          unitCountMicroUnits: newUnits,
          initialValuePaise: newInvested,
          currentValuationPaise: newValuation,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      return txId;
    });
  }

  /// Record a switch between two tracked holdings in FinBalance atomically.
  Future<void> recordSwitchBetweenHoldings({
    required int profileId,
    required int sourceItemId,
    required int destItemId,
    required int categoryId,
    required DateTime transactionDate,
    required int switchAmountPaise,
    int chargesPaise = 0,
    required int sourceUnitsMicroUnits,
    required int sourceNavMicroPaise,
    required int destUnitsMicroUnits,
    required int destNavMicroPaise,
    String? notes,
    String? sourceNotes,
    String? destNotes,
  }) async {
    return transaction(() async {
      // 1. Record switch-out from source
      final switchOutId = await recordInvestmentTransaction(
        profileId: profileId,
        financialItemId: sourceItemId,
        categoryId: categoryId,
        transactionType: 'switch_out',
        transactionDate: transactionDate,
        amountPaise: switchAmountPaise,
        chargesPaise: chargesPaise,
        unitsMicroUnits: sourceUnitsMicroUnits,
        unitPriceMicroPaise: sourceNavMicroPaise,
        notes: sourceNotes ?? notes,
      );

      // 2. Record switch-in to destination linked to switch-out
      final switchInId = await recordInvestmentTransaction(
        profileId: profileId,
        financialItemId: destItemId,
        categoryId: categoryId,
        transactionType: 'switch_in',
        transactionDate: transactionDate,
        amountPaise: switchAmountPaise - chargesPaise,
        chargesPaise: 0,
        unitsMicroUnits: destUnitsMicroUnits,
        unitPriceMicroPaise: destNavMicroPaise,
        linkedTransactionId: switchOutId,
        notes: destNotes ?? notes,
      );

      // 3. Update switch-out to link back to switch-in
      final tx = await getTransactionById(switchOutId);
      if (tx != null) {
        await updateTransaction(
            tx.copyWith(linkedTransactionId: Value(switchInId)));
      }
    });
  }
}
