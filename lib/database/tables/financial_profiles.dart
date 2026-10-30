import 'package:drift/drift.dart';

/// FinancialProfiles table for FinBalance.
///
/// Supports multi-person / family finance management within a single device.
/// Each profile represents an individual (e.g. Self, Spouse, Father, Mother, Child)
/// with completely isolated accounts, assets, liabilities, and transactions.
class FinancialProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Display name of the profile (e.g. "My Profile", "Father", "Priya")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Optional relative or custom avatar icon identifier/path
  TextColumn get avatarPath => text().nullable()();

  /// Optional notes or description
  TextColumn get description => text().nullable()();

  /// Relationship to primary user: 'self', 'father', 'mother', 'spouse', 'child', 'other'
  TextColumn get relationship => text()
      .withLength(min: 1, max: 50)
      .withDefault(const Constant('self'))();

  /// Color accent hex string for UI chips and avatars (e.g. '#10B981')
  TextColumn get colorHex => text()
      .withLength(min: 4, max: 9)
      .withDefault(const Constant('#10B981'))();

  /// Whether this is the default profile chosen on launch
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Whether the profile is archived (hidden from everyday dashboard, but records preserved)
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Creation timestamp (Unix seconds)
  IntColumn get createdAt =>
      integer().withDefault(currentDateAndTimeInSeconds)();

  /// Last updated timestamp (Unix seconds)
  IntColumn get updatedAt =>
      integer().withDefault(currentDateAndTimeInSeconds)();
}
