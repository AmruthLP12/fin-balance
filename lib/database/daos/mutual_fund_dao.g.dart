// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mutual_fund_dao.dart';

// ignore_for_file: type=lint
mixin _$MutualFundDaoMixin on DatabaseAccessor<AppDatabase> {
  $MutualFundSchemesTable get mutualFundSchemes =>
      attachedDatabase.mutualFundSchemes;
  $NavHistoryTable get navHistory => attachedDatabase.navHistory;
  $FinancialItemsTable get financialItems => attachedDatabase.financialItems;
  $ValuationHistoryTable get valuationHistory =>
      attachedDatabase.valuationHistory;
  MutualFundDaoManager get managers => MutualFundDaoManager(this);
}

class MutualFundDaoManager {
  final _$MutualFundDaoMixin _db;
  MutualFundDaoManager(this._db);
  $$MutualFundSchemesTableTableManager get mutualFundSchemes =>
      $$MutualFundSchemesTableTableManager(
          _db.attachedDatabase, _db.mutualFundSchemes);
  $$NavHistoryTableTableManager get navHistory =>
      $$NavHistoryTableTableManager(_db.attachedDatabase, _db.navHistory);
  $$FinancialItemsTableTableManager get financialItems =>
      $$FinancialItemsTableTableManager(
          _db.attachedDatabase, _db.financialItems);
  $$ValuationHistoryTableTableManager get valuationHistory =>
      $$ValuationHistoryTableTableManager(
          _db.attachedDatabase, _db.valuationHistory);
}
