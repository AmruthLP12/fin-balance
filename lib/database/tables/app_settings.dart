import 'package:drift/drift.dart';

/// Table storing local key-value application settings, user preferences,
/// and metadata timestamps.
class AppSettings extends Table {
  TextColumn get key => text().withLength(min: 1, max: 100)();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
