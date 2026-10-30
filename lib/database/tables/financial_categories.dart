import 'package:drift/drift.dart';

import 'financial_profiles.dart';

/// Table representing financial categories and subcategories across assets,
/// liabilities, income, and expenses.
///
/// Global categories have a NULL profileId.
/// Profile-specific custom categories specify their owner profileId.
@TableIndex(name: 'idx_category_classification', columns: {#classification})
@TableIndex(name: 'idx_category_profile', columns: {#profileId})
class FinancialCategories extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Profile scoping: NULL for system/global categories; non-null for profile-custom categories.
  IntColumn get profileId => integer().nullable().customConstraint(
      'REFERENCES financial_profiles(id) ON DELETE CASCADE')();

  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Classification: 'asset', 'liability', 'income', 'expense'
  TextColumn get classification => text()();

  IntColumn get parentId => integer().nullable().customConstraint(
      'REFERENCES financial_categories(id) ON DELETE SET NULL')();
  TextColumn get icon => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
