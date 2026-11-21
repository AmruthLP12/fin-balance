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

  /// Records a dated loan repayment and reduces the linked loan balance.
  Future<int> recordDebtRepayment({
    required int profileId,
    required int financialItemId,
    required int categoryId,
    required DateTime transactionDate,
    required int amountPaise,
    String? notes,
    String source = 'manual',
  }) async {
    if (amountPaise <= 0) {
      throw ArgumentError('Repayment amount must be greater than zero.');
    }

    return transaction(() async {
      final item = await db.financialItemsDao.getItemById(financialItemId);
      if (item == null || item.profileId != profileId) {
        throw ArgumentError('Loan does not belong to this profile.');
      }
      if (item.itemType != 'liability' || item.status != 'active') {
        throw ArgumentError('Only an active loan can receive repayments.');
      }

      final outstanding = item.currentValuationPaise;
      final updatedBalance =
          (outstanding - amountPaise).clamp(0, outstanding).toInt();
      final transactionId = await insertTransaction(
        TransactionsCompanion(
          profileId: Value(profileId),
          financialItemId: Value(financialItemId),
          transactionType: const Value('debt_repayment'),
          categoryId: Value(categoryId),
          transactionDate: Value(transactionDate),
          amountPaise: Value(amountPaise),
          netAmountPaise: Value(amountPaise),
          source: Value(source),
          notes: notes == null || notes.trim().isEmpty
              ? const Value.absent()
              : Value(notes.trim()),
        ),
      );
      await db.financialItemsDao.updateValuation(
        id: financialItemId,
        currentValuationPaise: updatedBalance,
      );
      if (updatedBalance == 0) {
        await (db.update(db.financialItems)
              ..where((tbl) => tbl.id.equals(financialItemId)))
            .write(const FinancialItemsCompanion(status: Value('closed')));
      }
      return transactionId;
    });
  }

  /// Starts an informal debt with a person: money you lent (an asset) or
  /// borrowed (a liability). No EMI or tenure. [ratePeriod] is 'monthly' or
  /// 'yearly' and [rateBasisPoints] the rate as entered (2% = 200).
  Future<int> openPersonalDebt({
    required int profileId,
    required bool lent,
    required String person,
    required int amountPaise,
    required DateTime date,
    int? rateBasisPoints,
    String ratePeriod = 'yearly',
    DateTime? endDate,
    DateTime? interestDueDate,
    int? interestDueAmountPaise,
    String? notes,
  }) async {
    if (amountPaise <= 0) throw ArgumentError('Amount must be above zero.');
    return transaction(() async {
      final cats = await db.categoriesDao
          .getCategoriesByClassification(lent ? 'asset' : 'liability');
      final categoryId = cats.isNotEmpty ? cats.first.id : 1;
      final itemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(profileId),
          name: Value(person),
          itemType: Value(lent ? 'asset' : 'liability'),
          subType: Value(lent ? 'money_lent' : 'other_liability'),
          categoryId: Value(categoryId),
          initialValuePaise: Value(amountPaise),
          currentValuationPaise: Value(amountPaise),
          lenderName: Value(person),
          interestRateBasisPoints: Value(rateBasisPoints),
          interestRateType: Value(ratePeriod),
          interestDueDate: Value(interestDueDate),
          interestDueAmountPaise: Value(interestDueAmountPaise),
          startDate: Value(date),
          maturityDate: Value(endDate),
          notes: notes == null || notes.trim().isEmpty
              ? const Value.absent()
              : Value(notes.trim()),
        ),
      );
      await insertTransaction(TransactionsCompanion(
        profileId: Value(profileId),
        financialItemId: Value(itemId),
        transactionType: Value(lent ? 'lend_given' : 'borrowing_received'),
        categoryId: Value(categoryId),
        transactionDate: Value(date),
        amountPaise: Value(amountPaise),
        netAmountPaise: Value(amountPaise),
        notes: Value(lent ? 'Lent to $person' : 'Borrowed from $person'),
      ));
      return itemId;
    });
  }

  /// A payment on an informal debt. Principal reduces what is outstanding
  /// (and closes the debt at zero); interest is only recorded.
  Future<int> recordPersonalEntry({
    required int itemId,
    required bool interest,
    required int amountPaise,
    required DateTime date,
    String? notes,
  }) async {
    if (amountPaise <= 0) throw ArgumentError('Amount must be above zero.');
    return transaction(() async {
      final item = await db.financialItemsDao.getItemById(itemId);
      if (item == null || item.status != 'active') {
        throw ArgumentError('This entry is closed.');
      }
      final lent = item.itemType == 'asset';
      final type = interest
          ? (lent ? 'interest_received' : 'interest_paid')
          : (lent ? 'lend_repaid' : 'debt_repayment');
      final amount = interest
          ? amountPaise
          : amountPaise.clamp(0, item.currentValuationPaise).toInt();
      if (amount <= 0) throw ArgumentError('Nothing left to repay.');
      final id = await insertTransaction(TransactionsCompanion(
        profileId: Value(item.profileId),
        financialItemId: Value(itemId),
        transactionType: Value(type),
        categoryId: Value(item.categoryId),
        transactionDate: Value(date),
        amountPaise: Value(amount),
        netAmountPaise: Value(amount),
        notes: notes == null || notes.trim().isEmpty
            ? const Value.absent()
            : Value(notes.trim()),
      ));
      if (!interest) {
        final left = item.currentValuationPaise - amount;
        await db.financialItemsDao
            .updateValuation(id: itemId, currentValuationPaise: left);
        if (left == 0) {
          await (db.update(db.financialItems)
                ..where((t) => t.id.equals(itemId)))
              .write(const FinancialItemsCompanion(status: Value('closed')));
        }
      }
      return id;
    });
  }

  /// Updates an existing principal or interest entry for an informal debt.
  /// Principal edits move the outstanding balance by the change in the entry.
  Future<void> updatePersonalEntry({
    required int transactionId,
    required int amountPaise,
    required DateTime date,
    String? notes,
  }) async {
    if (amountPaise <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }
    return transaction(() async {
      final entry = await getTransactionById(transactionId);
      if (entry == null || entry.financialItemId == null) {
        throw ArgumentError('Personal debt entry does not exist.');
      }
      final item =
          await db.financialItemsDao.getItemById(entry.financialItemId!);
      if (item == null) throw ArgumentError('Personal debt does not exist.');

      final principalTypes = {'lend_repaid', 'debt_repayment'};
      if (principalTypes.contains(entry.transactionType)) {
        final delta = amountPaise - entry.amountPaise;
        final left = (item.currentValuationPaise - delta)
            .clamp(0, item.initialValuePaise)
            .toInt();
        await db.financialItemsDao.updateValuation(
          id: item.id,
          currentValuationPaise: left,
        );
        await (db.update(db.financialItems)
              ..where((tbl) => tbl.id.equals(item.id)))
            .write(FinancialItemsCompanion(
          status: Value(left == 0 ? 'closed' : 'active'),
          updatedAt: Value(DateTime.now().toUtc()),
        ));
      }

      await updateTransaction(entry.copyWith(
        transactionDate: date,
        amountPaise: amountPaise,
        netAmountPaise: Value(amountPaise),
        notes:
            Value(notes == null || notes.trim().isEmpty ? null : notes.trim()),
        updatedAt: DateTime.now().toUtc(),
      ));
    });
  }

  /// Deletes an existing principal or interest entry and reverses principal
  /// impact on the outstanding debt balance.
  Future<void> deletePersonalEntry(int transactionId) async {
    return transaction(() async {
      final entry = await getTransactionById(transactionId);
      if (entry == null || entry.financialItemId == null) return;
      final item =
          await db.financialItemsDao.getItemById(entry.financialItemId!);
      if (item != null &&
          {'lend_repaid', 'debt_repayment'}.contains(entry.transactionType)) {
        final left = (item.currentValuationPaise + entry.amountPaise)
            .clamp(0, item.initialValuePaise)
            .toInt();
        await db.financialItemsDao.updateValuation(
          id: item.id,
          currentValuationPaise: left,
        );
        await (db.update(db.financialItems)
              ..where((tbl) => tbl.id.equals(item.id)))
            .write(FinancialItemsCompanion(
          status: const Value('active'),
          updatedAt: Value(DateTime.now().toUtc()),
        ));
      }
      await deleteTransaction(transactionId);
    });
  }

  /// Deletes an informal debt and every ledger entry belonging to it.
  Future<void> deletePersonalDebt(int itemId) async {
    return transaction(() async {
      await (delete(transactions)
            ..where((tbl) => tbl.financialItemId.equals(itemId)))
          .go();
      await db.financialItemsDao.deleteItem(itemId);
    });
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
      int latestNav = unitPriceMicroPaise ?? 0;
      final schemeCode = int.tryParse(holding.externalCode ?? '');
      if (schemeCode != null && schemeCode > 0) {
        final scheme = await db.mutualFundDao.getSchemeByCode(schemeCode);
        if (scheme != null &&
            scheme.latestNavMicroPaise != null &&
            scheme.latestNavMicroPaise! > 0) {
          latestNav = scheme.latestNavMicroPaise!;
        }
      }

      // No known NAV -> value at cost basis rather than inventing a price.
      final newValuation = latestNav > 0
          ? FinancialPrecision.calculateValuationPaise(
              unitCountMicroUnits: newUnits,
              navMicroPaise: latestNav,
            )
          : newInvested;

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
