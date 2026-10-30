// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_items_dao.dart';

// ignore_for_file: type=lint
mixin _$FinancialItemsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FinancialItemsTable get financialItems => attachedDatabase.financialItems;
  FinancialItemsDaoManager get managers => FinancialItemsDaoManager(this);
}

class FinancialItemsDaoManager {
  final _$FinancialItemsDaoMixin _db;
  FinancialItemsDaoManager(this._db);
  $$FinancialItemsTableTableManager get financialItems =>
      $$FinancialItemsTableTableManager(
          _db.attachedDatabase, _db.financialItems);
}
