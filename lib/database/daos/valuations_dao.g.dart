// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'valuations_dao.dart';

// ignore_for_file: type=lint
mixin _$ValuationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ValuationHistoryTable get valuationHistory =>
      attachedDatabase.valuationHistory;
  ValuationsDaoManager get managers => ValuationsDaoManager(this);
}

class ValuationsDaoManager {
  final _$ValuationsDaoMixin _db;
  ValuationsDaoManager(this._db);
  $$ValuationHistoryTableTableManager get valuationHistory =>
      $$ValuationHistoryTableTableManager(
          _db.attachedDatabase, _db.valuationHistory);
}
