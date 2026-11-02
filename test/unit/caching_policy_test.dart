import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/data/nav/models/nav_models.dart';
import 'package:finbalance/data/nav/nav_provider.dart';
import 'package:finbalance/data/nav/nav_sync_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

class MockCountingNavProvider implements NavProvider {
  int searchCount = 0;
  int detailsCount = 0;
  int latestNavCount = 0;

  @override
  String get providerId => 'mock_counting';

  @override
  String get providerName => 'Mock Counting Provider';

  int get priority => 1;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<MutualFundSearchResult>> searchSchemes(String query) async {
    searchCount++;
    return [
      MutualFundSearchResult(
        schemeCode: 125497,
        schemeName: 'Mock Scheme $query',
        planType: 'Direct',
        optionType: 'Growth',
      ),
    ];
  }

  @override
  Future<MutualFundSchemeDetail?> getSchemeDetails(int schemeCode,
      {bool includeHistoricalNav = false}) async {
    detailsCount++;
    return MutualFundSchemeDetail(
      schemeCode: schemeCode,
      schemeName: 'Mock Scheme Details',
      planType: 'Direct',
      optionType: 'Growth',
      latestNav: NavRecord(
        date: DateTime.now().toUtc(),
        navMicroPaise: 200000000,
      ),
      navHistory: [],
    );
  }

  @override
  Future<NavRecord?> getLatestNav(int schemeCode) async {
    latestNavCount++;
    return NavRecord(
      date: DateTime.now().toUtc(),
      navMicroPaise: 200000000,
    );
  }

  Future<List<NavRecord>> getNavHistory(int schemeCode,
      {DateTime? startDate}) async {
    return [];
  }
}

void main() {
  group('NAV Caching & Refresh Policy Tests', () {
    late AppDatabase db;
    late MockCountingNavProvider mockProvider;
    late NavSyncService syncService;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      mockProvider = MockCountingNavProvider();
      syncService = NavSyncService(
        mutualFundDao: db.mutualFundDao,
        financialItemsDao: db.financialItemsDao,
        providers: [mockProvider],
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'Search query cache hits in-memory cache without repeating remote queries',
        () async {
      expect(mockProvider.searchCount, equals(0));

      // 1st search
      final res1 = await syncService.searchSchemes('Parag');
      expect(res1.length, equals(1));
      expect(mockProvider.searchCount, equals(1));

      // 2nd search with identical query (case-insensitive)
      final res2 = await syncService.searchSchemes('parag');
      expect(res2.length, equals(1));
      expect(mockProvider.searchCount,
          equals(1)); // Did NOT call remote provider again!

      // Different query calls remote provider
      final res3 = await syncService.searchSchemes('HDFC');
      expect(res3.length, equals(1));
      expect(mockProvider.searchCount, equals(2));
    });

    test('isSyncDue respects daily, weekly, and manual frequency policies', () {
      final now = DateTime.now().toUtc();
      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      final twentyFiveHoursAgo = now.subtract(const Duration(hours: 25));
      final eightDaysAgo = now.subtract(const Duration(days: 8));

      // 1. Manual policy is never automatically due
      expect(syncService.isSyncDue(null, 'manual'), isFalse);
      expect(syncService.isSyncDue(twentyFiveHoursAgo, 'manual'), isFalse);
      expect(syncService.isSyncDue(eightDaysAgo, 'manual'), isFalse);

      // 2. Daily policy: due after 24 hours
      expect(syncService.isSyncDue(null, 'daily'), isTrue);
      expect(syncService.isSyncDue(twoHoursAgo, 'daily'), isFalse);
      expect(syncService.isSyncDue(twentyFiveHoursAgo, 'daily'), isTrue);

      // 3. Weekly policy: due after 7 days
      expect(syncService.isSyncDue(null, 'weekly'), isTrue);
      expect(syncService.isSyncDue(twentyFiveHoursAgo, 'weekly'), isFalse);
      expect(syncService.isSyncDue(eightDaysAgo, 'weekly'), isTrue);
    });

    test('getNextEligibleSync calculates exact future timestamp', () {
      final now = DateTime.now().toUtc();

      // Manual: null
      expect(syncService.getNextEligibleSync(now, 'manual'), isNull);

      // Daily: +24 hours
      final nextDaily = syncService.getNextEligibleSync(now, 'daily');
      expect(nextDaily, isNotNull);
      expect(nextDaily!.difference(now).inHours, equals(24));

      // Weekly: +7 days
      final nextWeekly = syncService.getNextEligibleSync(now, 'weekly');
      expect(nextWeekly, isNotNull);
      expect(nextWeekly!.difference(now).inDays, equals(7));
    });

    test('syncSchemeNav with force=false skips network when sync is not due',
        () async {
      const schemeCode = 125497;

      // Seed local scheme with recent sync
      await db.mutualFundDao.upsertScheme(
        MutualFundSchemesCompanion(
          schemeCode: const drift.Value(schemeCode),
          schemeName: const drift.Value('Test Fund'),
          latestNavMicroPaise: const drift.Value(150000000),
          latestNavDate: drift.Value(DateTime.now().toUtc()),
          lastSyncedAt: drift.Value(DateTime.now().toUtc()),
        ),
      );

      // syncSchemeNav with force=false and daily policy
      final res = await syncService.syncSchemeNav(schemeCode,
          force: false, frequency: 'daily');
      expect(res.success, isTrue);
      expect(res.provider, contains('Sync Not Due'));
      expect(mockProvider.latestNavCount, equals(0)); // Remote was NOT called!

      // syncSchemeNav with force=true forces remote fetch
      final forcedRes = await syncService.syncSchemeNav(schemeCode,
          force: true, frequency: 'daily');
      expect(forcedRes.success, isTrue);
      expect(mockProvider.latestNavCount, equals(1)); // Remote WAS called!
    });
  });
}
