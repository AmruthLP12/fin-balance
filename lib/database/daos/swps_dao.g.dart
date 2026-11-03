// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swps_dao.dart';

// ignore_for_file: type=lint
mixin _$SwpsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SwpPlansTable get swpPlans => attachedDatabase.swpPlans;
  $SwpSchedulePeriodsTable get swpSchedulePeriods =>
      attachedDatabase.swpSchedulePeriods;
  $SwpInstallmentsTable get swpInstallments => attachedDatabase.swpInstallments;
  SwpsDaoManager get managers => SwpsDaoManager(this);
}

class SwpsDaoManager {
  final _$SwpsDaoMixin _db;
  SwpsDaoManager(this._db);
  $$SwpPlansTableTableManager get swpPlans =>
      $$SwpPlansTableTableManager(_db.attachedDatabase, _db.swpPlans);
  $$SwpSchedulePeriodsTableTableManager get swpSchedulePeriods =>
      $$SwpSchedulePeriodsTableTableManager(
          _db.attachedDatabase, _db.swpSchedulePeriods);
  $$SwpInstallmentsTableTableManager get swpInstallments =>
      $$SwpInstallmentsTableTableManager(
          _db.attachedDatabase, _db.swpInstallments);
}
