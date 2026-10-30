import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/recurring_transactions.dart';

part 'recurring_transactions_dao.g.dart';

@DriftAccessor(tables: [RecurringTransactions])
class RecurringTransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringTransactionsDaoMixin {
  RecurringTransactionsDao(super.db);

  /// Watch all active recurring schedules.
  Stream<List<RecurringTransaction>> watchActiveSchedules() {
    return (select(recurringTransactions)
          ..where((tbl) => tbl.status.equals('active')))
        .watch();
  }

  /// Get active schedules by recurring type ('sip_investment', 'loan_emi', etc.).
  Future<List<RecurringTransaction>> getActiveSchedulesByType(
      String recurringType) {
    return (select(recurringTransactions)
          ..where((tbl) =>
              tbl.recurringType.equals(recurringType) &
              tbl.status.equals('active')))
        .get();
  }

  /// Watch active schedules by type.
  Stream<List<RecurringTransaction>> watchActiveSchedulesByType(
      String recurringType) {
    return (select(recurringTransactions)
          ..where((tbl) =>
              tbl.recurringType.equals(recurringType) &
              tbl.status.equals('active')))
        .watch();
  }

  /// Get schedule by ID.
  Future<RecurringTransaction?> getScheduleById(int id) {
    return (select(recurringTransactions)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get schedules for a specific financial item.
  Future<List<RecurringTransaction>> getSchedulesByItem(int financialItemId) {
    return (select(recurringTransactions)
          ..where((tbl) => tbl.financialItemId.equals(financialItemId)))
        .get();
  }

  /// Insert a new recurring schedule.
  Future<int> insertSchedule(RecurringTransactionsCompanion schedule) {
    return into(recurringTransactions).insert(schedule);
  }

  /// Update an existing schedule.
  Future<bool> updateSchedule(RecurringTransaction schedule) {
    return update(recurringTransactions).replace(schedule);
  }

  /// Update status (active, paused, completed, cancelled).
  Future<int> updateStatus(int id, String status) {
    return (update(recurringTransactions)..where((tbl) => tbl.id.equals(id)))
        .write(
      RecurringTransactionsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Delete a recurring schedule.
  Future<int> deleteSchedule(int id) {
    return (delete(recurringTransactions)..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}
