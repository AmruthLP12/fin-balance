import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:finbalance/data/nav/mfapi_provider.dart';
import 'package:finbalance/data/nav/nav_sync_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late NavSyncService service;
  final paths = <String>[];

  setUp(() {
    paths.clear();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final dio = Dio(BaseOptions(baseUrl: 'https://api.mfapi.in'))
      ..interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
        paths.add(o.path);
        final full = o.path == '/mf/1';
        h.resolve(Response(requestOptions: o, statusCode: 200, data: {
          'meta': {'scheme_code': 1, 'scheme_name': 'Test Fund Direct Growth'},
          'status': 'SUCCESS',
          'data': [
            {'date': '29-10-2026', 'nav': '20.0'},
            if (full) {'date': '01-01-2020', 'nav': '10.0'},
          ],
        }));
      }));
    service = NavSyncService(
      mutualFundDao: db.mutualFundDao,
      financialItemsDao: db.financialItemsDao,
      providers: [MFapiProvider(dio: dio)],
    );
  });

  tearDown(() => db.close());

  test('full history is downloaded once, then served from cache', () async {
    final first =
        await service.getOrFetchSchemeDetails(1, includeHistoricalNav: true);
    expect(first!.navHistory, hasLength(2));
    expect(paths, ['/mf/1']);

    await service.getOrFetchSchemeDetails(1, includeHistoricalNav: true);
    await service.getOrFetchSchemeDetails(1);
    expect(paths, ['/mf/1'], reason: 'fresh cache must not hit the network');
  });

  test('latest-only cache still fetches history when a caller needs it',
      () async {
    await service.getOrFetchSchemeDetails(1);
    expect(paths, ['/mf/1/latest']);
    await service.getOrFetchSchemeDetails(1, includeHistoricalNav: true);
    expect(paths, ['/mf/1/latest', '/mf/1']);
  });

  test('manual refresh policy never refetches a cached scheme', () async {
    await service.getOrFetchSchemeDetails(1, includeHistoricalNav: true);
    await service.getOrFetchSchemeDetails(1,
        includeHistoricalNav: true, refreshFrequency: 'manual');
    expect(paths, ['/mf/1']);
  });
}
