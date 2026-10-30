import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/financial_profiles.dart';

part 'profiles_dao.g.dart';

@DriftAccessor(tables: [FinancialProfiles])
class ProfilesDao extends DatabaseAccessor<AppDatabase>
    with _$ProfilesDaoMixin {
  ProfilesDao(super.db);

  /// Watch all non-archived profiles (or all if includeArchived is true).
  Stream<List<FinancialProfile>> watchAllProfiles({
    bool includeArchived = false,
  }) {
    final query = select(financialProfiles);
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false));
    }
    query.orderBy([
      (t) => OrderingTerm.desc(t.isDefault),
      (t) => OrderingTerm.asc(t.name),
    ]);
    return query.watch();
  }

  /// Get list of profiles.
  Future<List<FinancialProfile>> getAllProfiles({
    bool includeArchived = false,
  }) {
    final query = select(financialProfiles);
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false));
    }
    query.orderBy([
      (t) => OrderingTerm.desc(t.isDefault),
      (t) => OrderingTerm.asc(t.name),
    ]);
    return query.get();
  }

  /// Get single profile by ID.
  Future<FinancialProfile?> getProfileById(int id) {
    return (select(financialProfiles)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Watch a single profile by ID.
  Stream<FinancialProfile?> watchProfileById(int id) {
    return (select(financialProfiles)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Get the designated default profile.
  Future<FinancialProfile?> getDefaultProfile() {
    return (select(financialProfiles)
          ..where((tbl) => tbl.isDefault.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Create a new financial profile.
  Future<int> createProfile(FinancialProfilesCompanion profile) async {
    return transaction(() async {
      // If marked as default, clear other defaults first
      if (profile.isDefault.present && profile.isDefault.value) {
        await (update(financialProfiles)
              ..where((tbl) => tbl.isDefault.equals(true)))
            .write(const FinancialProfilesCompanion(isDefault: Value(false)));
      }
      return into(financialProfiles).insert(profile);
    });
  }

  /// Update an existing profile.
  Future<bool> updateProfile(FinancialProfilesCompanion profile) async {
    return transaction(() async {
      if (profile.isDefault.present && profile.isDefault.value) {
        await (update(financialProfiles)
              ..where((tbl) => tbl.isDefault.equals(true)))
            .write(const FinancialProfilesCompanion(isDefault: Value(false)));
      }
      return update(financialProfiles).replace(profile);
    });
  }

  /// Set a profile as the default.
  Future<void> setDefaultProfile(int id) async {
    await transaction(() async {
      await (update(financialProfiles))
          .write(const FinancialProfilesCompanion(isDefault: Value(false)));
      await (update(financialProfiles)..where((tbl) => tbl.id.equals(id)))
          .write(const FinancialProfilesCompanion(isDefault: Value(true)));
    });
  }

  /// Archive a profile (preserve records, hide from primary view).
  Future<int> archiveProfile(int id) async {
    return transaction(() async {
      final profile = await getProfileById(id);
      if (profile != null && profile.isDefault) {
        // Find another active profile to designate as default
        final alternative = await (select(financialProfiles)
              ..where(
                  (tbl) => tbl.id.isNotValue(id) & tbl.isArchived.equals(false))
              ..limit(1))
            .getSingleOrNull();
        if (alternative != null) {
          await (update(financialProfiles)
                ..where((tbl) => tbl.id.equals(alternative.id)))
              .write(const FinancialProfilesCompanion(isDefault: Value(true)));
        }
      }

      return (update(financialProfiles)..where((tbl) => tbl.id.equals(id)))
          .write(const FinancialProfilesCompanion(
        isArchived: Value(true),
        isDefault: Value(false),
      ));
    });
  }

  /// Unarchive a profile.
  Future<int> unarchiveProfile(int id) {
    return (update(financialProfiles)..where((tbl) => tbl.id.equals(id)))
        .write(const FinancialProfilesCompanion(
      isArchived: Value(false),
    ));
  }

  /// Permanently delete a profile and all its cascaded records.
  Future<int> deleteProfile(int id) {
    return (delete(financialProfiles)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Check if a profile has existing financial items, accounts, or transactions.
  Future<bool> hasFinancialHistory(int profileId) async {
    final itemsCount = await (db.selectOnly(db.financialItems)
          ..where(db.financialItems.profileId.equals(profileId))
          ..addColumns([countAll()]))
        .map((row) => row.read(countAll()) ?? 0)
        .getSingle();
    if (itemsCount > 0) return true;

    final txCount = await (db.selectOnly(db.transactions)
          ..where(db.transactions.profileId.equals(profileId))
          ..addColumns([countAll()]))
        .map((row) => row.read(countAll()) ?? 0)
        .getSingle();
    if (txCount > 0) return true;

    final accCount = await (db.selectOnly(db.financialAccounts)
          ..where(db.financialAccounts.profileId.equals(profileId))
          ..addColumns([countAll()]))
        .map((row) => row.read(countAll()) ?? 0)
        .getSingle();
    return accCount > 0;
  }

  /// Count active profiles.
  Future<int> countActiveProfiles() async {
    final count = countAll();
    final query = selectOnly(financialProfiles)
      ..where(financialProfiles.isArchived.equals(false))
      ..addColumns([count]);
    return await query.map((row) => row.read(count)!).getSingle();
  }
}
