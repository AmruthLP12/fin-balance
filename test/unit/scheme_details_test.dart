import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/data/nav/mfapi_provider.dart';
import 'package:finbalance/data/nav/models/nav_models.dart';
import 'package:finbalance/data/nav/nav_sync_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('Scheme Details & Parsing Tests', () {
    late Dio mockDio;

    setUp(() {
      mockDio = Dio(BaseOptions(baseUrl: 'https://api.mfapi.in'));
    });

    test('Parses complete valid scheme response with latest and historical NAV',
        () async {
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/mf/125497') {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'meta': {
                    'fund_house': 'SBI Mutual Fund',
                    'scheme_type': 'Open Ended Schemes',
                    'scheme_category': 'Equity Scheme - Small Cap Fund',
                    'scheme_code': 125497,
                    'scheme_name': 'SBI SMALL CAP FUND - Direct Plan - Growth',
                    'isin_growth': 'INF200K01T51',
                    'isin_div_reinvestment': null,
                  },
                  'data': [
                    {'date': '29-10-2026', 'nav': '200.18460'},
                    {'date': '28-10-2026', 'nav': '199.37080'},
                  ],
                  'status': 'SUCCESS',
                },
              ));
            }
            return handler.reject(DioException(requestOptions: options));
          },
        ),
      );

      final provider = MFapiProvider(dio: mockDio);
      final details =
          await provider.getSchemeDetails(125497, includeHistoricalNav: true);

      expect(details, isNotNull);
      expect(details!.schemeCode, equals(125497));
      expect(details.schemeName,
          equals('SBI SMALL CAP FUND - Direct Plan - Growth'));
      expect(details.fundHouse, equals('SBI Mutual Fund'));
      expect(details.schemeCategory, equals('Equity Scheme - Small Cap Fund'));
      expect(details.isin, equals('INF200K01T51'));
      expect(details.planType, equals('Direct'));
      expect(details.optionType, equals('Growth'));
      expect(details.latestNav, isNotNull);
      expect(details.latestNav!.navMicroPaise, equals(200184600));
      expect(details.navHistory.length, equals(2));
    });

    test('Parses scheme with missing metadata and empty NAV history gracefully',
        () async {
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'meta': {
                  'scheme_code': '100033',
                  'scheme_name': 'Sample Index Fund Regular Growth',
                  // fund_house, scheme_category, isin are all missing/null
                },
                'data': <dynamic>[],
                'status': 'SUCCESS',
              },
            ));
          },
        ),
      );

      final provider = MFapiProvider(dio: mockDio);
      final details = await provider.getSchemeDetails(100033);

      expect(details, isNotNull);
      expect(details!.schemeCode, equals(100033));
      expect(details.fundHouse, isNull);
      expect(details.schemeCategory, isNull);
      expect(details.latestNav, isNull);
      expect(details.navHistory, isEmpty);
      expect(details.planType, equals('Regular'));
      expect(details.optionType, equals('Growth'));
    });

    test('Handles malformed JSON and non-numeric NAV without crashing', () {
      final json = {
        'meta': {
          'scheme_code': 'invalid_code',
          'scheme_name': 'Corrupted Fund',
        },
        'data': [
          {'date': 'invalid-date', 'nav': 'N.A.'},
          {'date': '31-02-2026', 'nav': '10.50'},
        ],
      };

      final detail = MutualFundSchemeDetail.fromMfApiJson(json);
      expect(detail.schemeCode, equals(0));
      expect(detail.schemeName, equals('Corrupted Fund'));
      expect(detail.navHistory.length, equals(2));
      // First record has "N.A." nav which parses to 0 microPaise safely
      expect(detail.navHistory[0].navMicroPaise, equals(0));
    });

    test(
        'Returns cached scheme details when remote providers fail (offline fallback)',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      // Seed cached scheme in local SQLite
      await db.mutualFundDao.upsertScheme(
        MutualFundSchemesCompanion(
          schemeCode: const drift.Value(125497),
          schemeName: const drift.Value('SBI Small Cap Fund - Cached Offline'),
          fundHouse: const drift.Value('SBI Mutual Fund'),
          planType: const drift.Value('Direct'),
          optionType: const drift.Value('Growth'),
          latestNavMicroPaise: const drift.Value(195000000),
          latestNavDate: drift.Value(DateTime.utc(2026, 10, 25)),
        ),
      );

      // Provider that always fails with connection timeout
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.connectionTimeout,
            ));
          },
        ),
      );

      final syncService = NavSyncService(
        mutualFundDao: db.mutualFundDao,
        financialItemsDao: db.financialItemsDao,
        providers: [MFapiProvider(dio: mockDio)],
      );

      // Force refresh is false -> returns cached directly
      final cachedDetails = await syncService.getOrFetchSchemeDetails(125497);
      expect(cachedDetails, isNotNull);
      expect(cachedDetails!.schemeName,
          equals('SBI Small Cap Fund - Cached Offline'));
      expect(cachedDetails.latestNav?.navMicroPaise, equals(195000000));

      // Force refresh is true -> provider fails, falls back to cached scheme
      final fallbackDetails = await syncService.getOrFetchSchemeDetails(
        125497,
        forceRefresh: true,
      );
      expect(fallbackDetails, isNotNull);
      expect(fallbackDetails!.schemeName,
          equals('SBI Small Cap Fund - Cached Offline'));

      await db.close();
    });

    test('Fallback from full history to latest endpoint on timeout', () async {
      var fullHistoryAttempted = false;
      var latestAttempted = false;

      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/mf/125497') {
              fullHistoryAttempted = true;
              return handler.reject(DioException(
                requestOptions: options,
                type: DioExceptionType.receiveTimeout,
              ));
            } else if (options.path == '/mf/125497/latest') {
              latestAttempted = true;
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'meta': {
                    'scheme_code': 125497,
                    'scheme_name': 'SBI Small Cap Fund',
                  },
                  'data': [
                    {'date': '29-10-2026', 'nav': '200.18'},
                  ],
                  'status': 'SUCCESS',
                },
              ));
            }
            return handler.reject(DioException(requestOptions: options));
          },
        ),
      );

      final provider = MFapiProvider(dio: mockDio);
      final detail =
          await provider.getSchemeDetails(125497, includeHistoricalNav: true);

      expect(fullHistoryAttempted, isTrue);
      expect(latestAttempted, isTrue);
      expect(detail, isNotNull);
      expect(detail!.schemeCode, equals(125497));
      expect(detail.latestNav?.navMicroPaise, equals(200180000));
    });
  });
}
