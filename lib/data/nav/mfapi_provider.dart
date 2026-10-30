import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'models/nav_models.dart';
import 'nav_provider.dart';

/// Primary mutual fund & NAV provider using MFapi.in.
class MFapiProvider implements NavProvider {
  final Dio _dio;

  MFapiProvider({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.mfapi.in',
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 20),
                headers: {
                  'Accept': 'application/json',
                  if (!kIsWeb)
                    'User-Agent':
                        'FinBalance/1.0 (Android; Offline-First Personal Finance)',
                },
              ),
            );

  @override
  String get providerId => 'mfapi';

  @override
  String get providerName => 'MFapi.in';

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.get<dynamic>(
        '/mf/search',
        queryParameters: {'q': 'SBI'},
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<MutualFundSearchResult>> searchSchemes(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    try {
      final response = await _dio.get<dynamic>(
        '/mf/search',
        queryParameters: {'q': clean},
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List<dynamic>;
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => MutualFundSearchResult.fromJson(item))
            .where((item) => item.schemeCode > 0 && item.schemeName.isNotEmpty)
            .toList();
      }
      return [];
    } on DioException {
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
    if (schemeCode <= 0) return null;

    // Try full history if requested, otherwise latest NAV
    final primaryPath =
        includeHistoricalNav ? '/mf/$schemeCode' : '/mf/$schemeCode/latest';

    MutualFundSchemeDetail? detail = await _fetchDetailFromPath(primaryPath);

    // If full history path failed or timed out, attempt fallback to latest NAV
    if (detail == null && includeHistoricalNav) {
      detail = await _fetchDetailFromPath('/mf/$schemeCode/latest');
    }

    return detail;
  }

  Future<MutualFundSchemeDetail?> _fetchDetailFromPath(String path) async {
    try {
      final response = await _dio.get<dynamic>(path);
      if (response.statusCode == 200 && response.data != null) {
        Map<String, dynamic>? data;
        if (response.data is Map<String, dynamic>) {
          data = response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          data = Map<String, dynamic>.from(response.data as Map);
        } else if (response.data is String) {
          try {
            final decoded = json.decode(response.data as String);
            if (decoded is Map) {
              data = Map<String, dynamic>.from(decoded);
            }
          } catch (_) {}
        }

        if (data != null &&
            (data['status'] == 'SUCCESS' ||
                data['meta'] != null ||
                data['data'] != null)) {
          return MutualFundSchemeDetail.fromMfApiJson(data);
        }
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
