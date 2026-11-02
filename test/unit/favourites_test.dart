import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('Mutual Fund Favourites & Profile Isolation Tests', () {
    late AppDatabase db;
    late int profile1Id;
    late int profile2Id;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());

      profile1Id = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Family Member 1'),
          relationship: drift.Value('Self'),
        ),
      );

      profile2Id = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Family Member 2'),
          relationship: drift.Value('Spouse'),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Toggles favorite state on and off with persistence', () async {
      const schemeCode = 125497;
      const schemeName = 'SBI Small Cap Fund';

      // 1. Initial state: not favorite
      var isFav =
          await db.mutualFundDao.isSchemeFavorite(profile1Id, schemeCode);
      expect(isFav, isFalse);

      // 2. Toggle ON
      final resultOn = await db.mutualFundDao.toggleFavorite(
        profileId: profile1Id,
        schemeCode: schemeCode,
        schemeName: schemeName,
      );
      expect(resultOn, isTrue);

      isFav = await db.mutualFundDao.isSchemeFavorite(profile1Id, schemeCode);
      expect(isFav, isTrue);

      var favoritesList =
          await db.mutualFundDao.getFavoriteSchemesForProfile(profile1Id);
      expect(favoritesList.length, equals(1));
      expect(favoritesList.first.schemeCode, equals(schemeCode));

      // 3. Toggle OFF
      final resultOff = await db.mutualFundDao.toggleFavorite(
        profileId: profile1Id,
        schemeCode: schemeCode,
        schemeName: schemeName,
      );
      expect(resultOff, isFalse);

      isFav = await db.mutualFundDao.isSchemeFavorite(profile1Id, schemeCode);
      expect(isFav, isFalse);

      favoritesList =
          await db.mutualFundDao.getFavoriteSchemesForProfile(profile1Id);
      expect(favoritesList.isEmpty, isTrue);
    });

    test(
        'Favourites are strictly isolated per financial profile without leakage',
        () async {
      const schemeA = 125497;
      const schemeB = 100033;

      // Profile 1 favorites Scheme A
      await db.mutualFundDao.toggleFavorite(
        profileId: profile1Id,
        schemeCode: schemeA,
        schemeName: 'Scheme A',
      );

      // Profile 2 favorites Scheme B
      await db.mutualFundDao.toggleFavorite(
        profileId: profile2Id,
        schemeCode: schemeB,
        schemeName: 'Scheme B',
      );

      // Verify Profile 1 sees only Scheme A
      final p1Favs =
          await db.mutualFundDao.getFavoriteSchemesForProfile(profile1Id);
      expect(p1Favs.length, equals(1));
      expect(p1Favs.first.schemeCode, equals(schemeA));
      expect(
          await db.mutualFundDao.isSchemeFavorite(profile1Id, schemeA), isTrue);
      expect(await db.mutualFundDao.isSchemeFavorite(profile1Id, schemeB),
          isFalse);

      // Verify Profile 2 sees only Scheme B
      final p2Favs =
          await db.mutualFundDao.getFavoriteSchemesForProfile(profile2Id);
      expect(p2Favs.length, equals(1));
      expect(p2Favs.first.schemeCode, equals(schemeB));
      expect(await db.mutualFundDao.isSchemeFavorite(profile2Id, schemeA),
          isFalse);
      expect(
          await db.mutualFundDao.isSchemeFavorite(profile2Id, schemeB), isTrue);
    });

    test('Prevents duplicate entries in profile_favorite_schemes table',
        () async {
      const schemeCode = 125497;

      // Ensure master scheme exists first
      await db.mutualFundDao.upsertScheme(
        const MutualFundSchemesCompanion(
          schemeCode: drift.Value(schemeCode),
          schemeName: drift.Value('Scheme 125497'),
        ),
      );

      // Direct insert 1
      await db.into(db.profileFavoriteSchemes).insert(
            ProfileFavoriteSchemesCompanion(
              profileId: drift.Value(profile1Id),
              schemeCode: const drift.Value(schemeCode),
            ),
            onConflict: drift.DoNothing(
              target: [
                db.profileFavoriteSchemes.profileId,
                db.profileFavoriteSchemes.schemeCode
              ],
            ),
          );

      // Direct insert 2 with identical profileId and schemeCode
      await db.into(db.profileFavoriteSchemes).insert(
            ProfileFavoriteSchemesCompanion(
              profileId: drift.Value(profile1Id),
              schemeCode: const drift.Value(schemeCode),
            ),
            onConflict: drift.DoNothing(
              target: [
                db.profileFavoriteSchemes.profileId,
                db.profileFavoriteSchemes.schemeCode
              ],
            ),
          );

      final count = await (db.select(db.profileFavoriteSchemes)
            ..where((tbl) =>
                tbl.profileId.equals(profile1Id) &
                tbl.schemeCode.equals(schemeCode)))
          .get();

      expect(count.length, equals(1));
    });

    test('Emits reactive updates on favorite stream when toggled', () async {
      const schemeCode = 125497;
      final stream =
          db.mutualFundDao.watchIsSchemeFavorite(profile1Id, schemeCode);

      final streamExpectation = expectLater(
        stream,
        emitsInOrder([
          false, // Initially false
          true, // After toggle ON
          false, // After toggle OFF
        ]),
      );

      // Wait a tick then toggle ON
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await db.mutualFundDao.toggleFavorite(
        profileId: profile1Id,
        schemeCode: schemeCode,
        schemeName: 'Reactive Test Scheme',
      );

      // Wait a tick then toggle OFF
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await db.mutualFundDao.toggleFavorite(
        profileId: profile1Id,
        schemeCode: schemeCode,
        schemeName: 'Reactive Test Scheme',
      );

      await streamExpectation;
    });
  });
}
