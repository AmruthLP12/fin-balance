import 'package:drift/drift.dart';

/// Table representing mutual fund schemes bookmarked as favourites,
/// scoped to an individual profile with unique constraint preventing duplicate bookmarks.
@TableIndex(name: 'idx_fav_profile', columns: {#profileId})
@TableIndex(name: 'idx_fav_scheme', columns: {#schemeCode})
class ProfileFavoriteSchemes extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Profile scoping: Favourites are owned by a specific profile
  IntColumn get profileId => integer().customConstraint(
      'NOT NULL REFERENCES financial_profiles(id) ON DELETE CASCADE')();

  /// Scheme code: Unique identifier of the mutual fund scheme
  IntColumn get schemeCode => integer().customConstraint(
      'NOT NULL REFERENCES mutual_fund_schemes(scheme_code) ON DELETE CASCADE')();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {profileId, schemeCode},
      ];
}
