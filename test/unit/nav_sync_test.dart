import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/data/nav/mfapi_provider.dart';
import 'package:finbalance/data/nav/nav_sync_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('Manual NAV Synchronization & Rules', () {
    late AppDatabase db;
    late Dio mockDio;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      mockDio = Dio(BaseOptions(baseUrl: 'https://api.mfapi.in'));

      // Categories
      final cat = await db.categoriesDao.getCategoriesByClassification('asset');
      if (cat.isEmpty) {
        await db.into(db.financialCategories).insert(
              const FinancialCategoriesCompanion(
                id: drift.Value(1),
                name: drift.Value('Mutual Funds'),
                classification: drift.Value('asset'),
              ),
            );
      }
    });

    tearDown(() async {
      await db.close();
    });

    test('syncSchemeNav updates latest NAV, history, and holding valuation',
        () async {
      // Seed a holding with 100.0 units (100,000,000 micro-units) at ₹10,000 (1,000,000 paise)
      await db.financialItemsDao.insertItem(
        const FinancialItemsCompanion(
          id: drift.Value(1),
          profileId: drift.Value(1),
          name: drift.Value('SBI Small Cap Fund'),
          itemType: drift.Value('asset'),
          subType: drift.Value('mutual_fund'),
          categoryId: drift.Value(1),
          externalCode: drift.Value('125497'),
          initialValuePaise: drift.Value(1000000), // ₹10,000 invested
          currentValuationPaise: drift.Value(1000000),
          unitCountMicroUnits: drift.Value(100000000), // 100 units
        ),
      );

      // Mock MFapi returning NAV of 200.00 (200,000,000 micro-paise)
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/mf/125497/latest') {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'meta': {
                    'scheme_code': 125497,
                    'scheme_name': 'SBI SMALL CAP FUND - Direct Plan - Growth',
                  },
                  'data': [
                    {'date': '29-10-2026', 'nav': '200.00000'},
                  ],
                  'status': 'SUCCESS',
                },
              ));
            }
            return handler.reject(DioException(requestOptions: options));
          },
        ),
      );

      final syncService = NavSyncService(
        mutualFundDao: db.mutualFundDao,
        financialItemsDao: db.financialItemsDao,
        providers: [MFapiProvider(dio: mockDio)],
      );

      final result = await syncService.syncSchemeNav(125497);

      expect(result.success, isTrue);
      expect(result.navMicroPaise, equals(200000000));
      expect(result.provider, equals('MFapi.in'));

      // Check scheme master updated
      final scheme = await db.mutualFundDao.getSchemeByCode(125497);
      expect(scheme, isNotNull);
      expect(scheme!.latestNavMicroPaise, equals(200000000));
      expect(scheme.lastSyncedAt, isNotNull);

      // Check NAV history inserted
      final history = await db.mutualFundDao.getNavHistory(125497);
      expect(history.length, equals(1));
      expect(history.first.navMicroPaise, equals(200000000));

      // Check holding currentValuation updated: 100 units * 200 = ₹20,000 (2,000,000 paise)
      final holding = await db.financialItemsDao.getItemById(1);
      expect(holding, isNotNull);
      expect(holding!.currentValuationPaise, equals(2000000));
    });

    test('Prevents duplicate NAV entries on repeated sync', () async {
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'meta': {'scheme_code': 125497, 'scheme_name': 'Test Scheme'},
                'data': [
                  {'date': '29-10-2026', 'nav': '200.00'},
                ],
                'status': 'SUCCESS',
              },
            ));
          },
        ),
      );

      final syncService = NavSyncService(
        mutualFundDao: db.mutualFundDao,
        financialItemsDao: db.financialItemsDao,
        providers: [MFapiProvider(dio: mockDio)],
      );

      // Run sync twice with identical date
      await syncService.syncSchemeNav(125497);
      await syncService.syncSchemeNav(125497);

      final history = await db.mutualFundDao.getNavHistory(125497);
      // SQLite unique constraint on (scheme_code, nav_date) ensures only 1 entry
      expect(history.length, equals(1));
    });

    test('Does not overwrite newer NAV with older NAV', () async {
      // Seed scheme with newer NAV (29-10-2026 @ 210.00)
      await db.mutualFundDao.upsertScheme(
        MutualFundSchemesCompanion(
          schemeCode: const drift.Value(125497),
          schemeName: const drift.Value('Test Scheme'),
          latestNavMicroPaise: const drift.Value(210000000),
          latestNavDate: drift.Value(DateTime.utc(2026, 10, 29)),
        ),
      );

      // Provider returns older NAV (25-10-2026 @ 200.00)
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'meta': {'scheme_code': 125497, 'scheme_name': 'Test Scheme'},
                'data': [
                  {'date': '25-10-2026', 'nav': '200.00'},
                ],
                'status': 'SUCCESS',
              },
            ));
          },
        ),
      );

      final syncService = NavSyncService(
        mutualFundDao: db.mutualFundDao,
        financialItemsDao: db.financialItemsDao,
        providers: [MFapiProvider(dio: mockDio)],
      );

      await syncService.syncSchemeNav(125497);

      final scheme = await db.mutualFundDao.getSchemeByCode(125497);
      expect(scheme, isNotNull);
      // Preserves 210.00 (from Oct 29) rather than downgrading to 200.00 (from Oct 25)
      expect(scheme!.latestNavMicroPaise, equals(210000000));
      expect(scheme.latestNavDate!.isAtSameMomentAs(DateTime.utc(2026, 10, 29)),
          isTrue);
    });

    test('syncAllPortfolioSchemes syncs all portfolio holdings and favorites',
        () async {
      // Add 2 active mutual fund holdings
      await db.financialItemsDao.insertItem(
        const FinancialItemsCompanion(
          id: drift.Value(1),
          profileId: drift.Value(1),
          name: drift.Value('Fund 1'),
          itemType: drift.Value('asset'),
          subType: drift.Value('mutual_fund'),
          categoryId: drift.Value(1),
          externalCode: drift.Value('100001'),
        ),
      );
      await db.financialItemsDao.insertItem(
        const FinancialItemsCompanion(
          id: drift.Value(2),
          profileId: drift.Value(1),
          name: drift.Value('Fund 2'),
          itemType: drift.Value('asset'),
          subType: drift.Value('mutual_fund'),
          categoryId: drift.Value(1),
          externalCode: drift.Value('100002'),
        ),
      );

      // Add 1 favorite scheme not currently held
      await db.mutualFundDao.upsertScheme(
        const MutualFundSchemesCompanion(
          schemeCode: drift.Value(100003),
          schemeName: drift.Value('Bookmarked Fund 3'),
          isFavorite: drift.Value(true),
        ),
      );

      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final path = options.path;
            if (path == '/mf/100001/latest' ||
                path == '/mf/100002/latest' ||
                path == '/mf/100003/latest') {
              final codeStr = path.split('/')[2];
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'meta': {
                    'scheme_code': int.parse(codeStr),
                    'scheme_name': 'Scheme $codeStr',
                  },
                  'data': [
                    {'date': '29-10-2026', 'nav': '150.00'},
                  ],
                  'status': 'SUCCESS',
                },
              ));
            }
            return handler.reject(DioException(requestOptions: options));
          },
        ),
      );

      final syncService = NavSyncService(
        mutualFundDao: db.mutualFundDao,
        financialItemsDao: db.financialItemsDao,
        providers: [MFapiProvider(dio: mockDio)],
      );

      final summary = await syncService.syncAllPortfolioSchemes();

      expect(summary.totalSchemes, equals(3));
      expect(summary.successCount, equals(3));
      expect(summary.failedCount, equals(0));
      expect(summary.primaryProvider, equals('MFapi.in'));

      // Check setting was saved
      final lastSyncStr =
          await db.appSettingsDao.getSetting('last_nav_sync_time');
      expect(lastSyncStr, isNotNull);
    });

    test(
        'Reports failure cleanly when offline without throwing unhandled exceptions',
        () async {
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ));
          },
        ),
      );

      final syncService = NavSyncService(
        mutualFundDao: db.mutualFundDao,
        financialItemsDao: db.financialItemsDao,
        providers: [MFapiProvider(dio: mockDio)],
      );

      final res = await syncService.syncSchemeNav(125497);
      expect(res.success, isFalse);
      expect(res.errorMessage, isNotNull);
    });
  });
}
