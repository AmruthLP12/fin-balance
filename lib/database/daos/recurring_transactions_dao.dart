import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/recurring_transactions.dart';

part 'recurring_transactions_dao.g.dart';

@DriftAccessor(tables: [RecurringTransactions])
class RecurringTransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringTransactionsDaoMixin {
  RecurringTransactionsDao(super.db);

  /// Watch active recurring schedules for a specific profile.
  Stream<List<RecurringTransaction>> watchActiveSchedulesByProfile(
    int profileId, {
    String? recurringType,
  }) {
    final query = select(recurringTransactions)
      ..where((tbl) =>
          tbl.profileId.equals(profileId) & tbl.status.equals('active'));
    if (recurringType != null) {
      query.where((tbl) => tbl.recurringType.equals(recurringType));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Get active schedules for a specific profile.
  Future<List<RecurringTransaction>> getActiveSchedulesByProfile(
    int profileId, {
    String? recurringType,
  }) {
    final query = select(recurringTransactions)
      ..where((tbl) =>
          tbl.profileId.equals(profileId) & tbl.status.equals('active'));
    if (recurringType != null) {
      query.where((tbl) => tbl.recurringType.equals(recurringType));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.get();
  }

  /// Watch active schedules across all profiles (household level).
  Stream<List<RecurringTransaction>> watchHouseholdActiveSchedules({
    String? recurringType,
  }) {
    final query = select(recurringTransactions)
      ..where((tbl) => tbl.status.equals('active'));
    if (recurringType != null) {
      query.where((tbl) => tbl.recurringType.equals(recurringType));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Get schedule by ID.
  Future<RecurringTransaction?> getScheduleById(int id) {
    return (select(recurringTransactions)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get schedules for a specific financial item within a profile.
  Future<List<RecurringTransaction>> getSchedulesByItem(
    int profileId,
    int financialItemId,
  ) {
    return (select(recurringTransactions)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.financialItemId.equals(financialItemId)))
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
