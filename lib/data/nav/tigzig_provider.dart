import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'models/nav_models.dart';
import 'nav_provider.dart';

/// Secondary mutual fund provider: TIGZIG (https://api.tigzig.com/mf/v1/).
///
/// Note: TIGZIG's endpoint is protected by Cloudflare and frequently returns HTTP 403 (Error 1006).
/// This adapter cleanly detects Cloudflare restrictions, gracefully reports unavailable,
/// and never attempts unauthorized bypasses.
class TigzigProvider implements NavProvider {
  final Dio _dio;

  TigzigProvider({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.tigzig.com/mf/v1',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Accept': 'application/json, text/plain, */*',
                  if (!kIsWeb)
                    'User-Agent':
                        'Mozilla/5.0 (Linux; Android 14; FinBalance) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                },
              ),
            );

  @override
  String get providerId => 'tigzig';

  @override
  String get providerName => 'TIGZIG';

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.get<dynamic>(
        '/',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Cloudflare error 1006 returns 403
      if (response.statusCode == 403 ||
          (response.data is String &&
              (response.data as String).contains('error code: 1006'))) {
        return false;
      }
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<MutualFundSearchResult>> searchSchemes(String query) async {
    final available = await isAvailable();
    if (!available) return [];

    try {
      final response = await _dio.get<dynamic>(
        '/search',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map((item) => MutualFundSearchResult.fromJson(item))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<MutualFundSchemeDetail?> getSchemeDetails(
    int schemeCode, {
    bool includeHistoricalNav = false,
  }) async {
    final available = await isAvailable();
    if (!available) return null;

    try {
      final response = await _dio.get<dynamic>('/scheme/$schemeCode');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return MutualFundSchemeDetail.fromMfApiJson(
            response.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<NavRecord?> getLatestNav(int schemeCode) async {
    final detail =
        await getSchemeDetails(schemeCode, includeHistoricalNav: false);
    return detail?.latestNav;
  }
}
