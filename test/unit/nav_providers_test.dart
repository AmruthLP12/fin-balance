import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/data/nav/amfi_provider.dart';
import 'package:finbalance/data/nav/mfapi_provider.dart';
import 'package:finbalance/data/nav/tigzig_provider.dart';

void main() {
  group('MFapiProvider Integration & Failover', () {
    late Dio mockDio;

    setUp(() {
      mockDio = Dio(BaseOptions(baseUrl: 'https://api.mfapi.in'));
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/mf/search') {
              final query = options.queryParameters['q'];
              if (query == 'SBI') {
                return handler.resolve(Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'schemeCode': 125497,
                      'schemeName': 'SBI SMALL CAP FUND - Direct Plan - Growth',
                    },
                    {
                      'schemeCode': 100121,
                      'schemeName': 'SBI Magnum Midcap Fund - Regular Plan',
                    },
                  ],
                ));
              } else {
                return handler.resolve(Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: <Map<String, dynamic>>[],
                ));
              }
            } else if (options.path == '/mf/125497/latest') {
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
                  },
                  'data': [
                    {'date': '29-10-2026', 'nav': '200.18460'},
                  ],
                  'status': 'SUCCESS',
                },
              ));
            } else if (options.path == '/mf/999999/latest') {
              return handler.reject(DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: 404),
                type: DioExceptionType.badResponse,
              ));
            }

            return handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.connectionTimeout,
            ));
          },
        ),
      );
    });

    test('searchSchemes returns parsed mutual fund items', () async {
      final provider = MFapiProvider(dio: mockDio);
      final results = await provider.searchSchemes('SBI');

      expect(results.length, equals(2));
      expect(results[0].schemeCode, equals(125497));
      expect(results[0].planType, equals('Direct'));
      expect(results[0].optionType, equals('Growth'));
    });

    test('getSchemeDetails returns parsed scheme and latest NAV', () async {
      final provider = MFapiProvider(dio: mockDio);
      final detail = await provider.getSchemeDetails(125497);

      expect(detail, isNotNull);
      expect(detail!.schemeCode, equals(125497));
      expect(detail.latestNav, isNotNull);
      expect(detail.latestNav!.navMicroPaise, equals(200184600));
    });

    test('handles 404 and network errors gracefully without throwing',
        () async {
      final provider = MFapiProvider(dio: mockDio);
      final detail = await provider.getSchemeDetails(999999);
      expect(detail, isNull);

      final emptySearch = await provider.searchSchemes('NON_EXISTENT');
      expect(emptySearch, isEmpty);
    });
  });

  group('TigzigProvider Cloudflare 1006 Handling', () {
    test('reports unavailable when Cloudflare blocks with 403', () async {
      final mockDio = Dio(BaseOptions(baseUrl: 'https://api.tigzig.com/mf/v1'));
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 403,
              data: 'error code: 1006',
            ));
          },
        ),
      );

      final provider = TigzigProvider(dio: mockDio);
      final isAvailable = await provider.isAvailable();
      expect(isAvailable, isFalse);

      final results = await provider.searchSchemes('HDFC');
      expect(results, isEmpty);
    });
  });

  group('AmfiProvider Semicolon Text Parser', () {
    late Dio mockDio;

    setUp(() {
      const amfiSample = '''
Scheme Code;ISIN Div Payout/ ISIN Growth;ISIN Div Reinvestment;Scheme Name;Plan;Option;Net Asset Value;Date

Open Ended Schemes(Equity Scheme - Small Cap Fund)

SBI Mutual Fund

125497;INF200K01T51;-;SBI SMALL CAP FUND;Direct Plan;Growth;200.1846;29-Oct-2026
125496;INF200K01S03;-;SBI SMALL CAP FUND;Regular Plan;Growth;185.4210;29-Oct-2026
''';

      mockDio = Dio(BaseOptions(baseUrl: 'https://portal.amfiindia.com'));
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: amfiSample,
            ));
          },
        ),
      );
    });

    test('searches and parses schemes from raw AMFI text format', () async {
      final provider = AmfiProvider(dio: mockDio);
      final results = await provider.searchSchemes('small cap');

      expect(results.length, equals(2));
      expect(results.any((r) => r.schemeCode == 125497), isTrue);
      expect(results.any((r) => r.schemeCode == 125496), isTrue);
    });

    test('extracts scheme details and parses DD-MMM-YYYY date with NAV',
        () async {
      final provider = AmfiProvider(dio: mockDio);
      final detail = await provider.getSchemeDetails(125497);

      expect(detail, isNotNull);
      expect(detail!.schemeCode, equals(125497));
      expect(detail.isin, equals('INF200K01T51'));
      expect(detail.latestNav, isNotNull);
      expect(detail.latestNav!.navMicroPaise, equals(200184600));
      expect(detail.latestNav!.date.year, equals(2026));
      expect(detail.latestNav!.date.month, equals(10));
      expect(detail.latestNav!.date.day, equals(29));
    });
  });
}
