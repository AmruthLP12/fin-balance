// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sips_dao.dart';

// ignore_for_file: type=lint
mixin _$SipsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SipPlansTable get sipPlans => attachedDatabase.sipPlans;
  $SipSchedulePeriodsTable get sipSchedulePeriods =>
      attachedDatabase.sipSchedulePeriods;
  $SipInstallmentsTable get sipInstallments => attachedDatabase.sipInstallments;
  $MutualFundSchemesTable get mutualFundSchemes =>
      attachedDatabase.mutualFundSchemes;
  $FinancialItemsTable get financialItems => attachedDatabase.financialItems;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  SipsDaoManager get managers => SipsDaoManager(this);
}

class SipsDaoManager {
  final _$SipsDaoMixin _db;
  SipsDaoManager(this._db);
  $$SipPlansTableTableManager get sipPlans =>
      $$SipPlansTableTableManager(_db.attachedDatabase, _db.sipPlans);
  $$SipSchedulePeriodsTableTableManager get sipSchedulePeriods =>
      $$SipSchedulePeriodsTableTableManager(
          _db.attachedDatabase, _db.sipSchedulePeriods);
  $$SipInstallmentsTableTableManager get sipInstallments =>
      $$SipInstallmentsTableTableManager(
          _db.attachedDatabase, _db.sipInstallments);
  $$MutualFundSchemesTableTableManager get mutualFundSchemes =>
      $$MutualFundSchemesTableTableManager(
          _db.attachedDatabase, _db.mutualFundSchemes);
  $$FinancialItemsTableTableManager get financialItems =>
      $$FinancialItemsTableTableManager(
          _db.attachedDatabase, _db.financialItems);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
}
