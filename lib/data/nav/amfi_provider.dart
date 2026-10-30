import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../database/precision/financial_precision.dart';
import 'models/nav_models.dart';
import 'nav_provider.dart';

/// Tertiary fallback provider: Official AMFI NAV text file.
/// Endpoint: https://portal.amfiindia.com/spages/NAVAll.txt
/// Format: Semicolon delimited lines:
/// Scheme Code;ISIN Div Payout/ ISIN Growth;ISIN Div Reinvestment;Scheme Name;Plan;Option;Net Asset Value;Date
class AmfiProvider implements NavProvider {
  final Dio _dio;

  AmfiProvider({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://portal.amfiindia.com',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  if (!kIsWeb)
                    'User-Agent':
                        'FinBalance/1.0 (Android; Offline-First Personal Finance)',
                },
              ),
            );

  @override
  String get providerId => 'amfi';

  @override
  String get providerName => 'AMFI India';

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.get<dynamic>(
        '/spages/NAVAll.txt',
        options: Options(
          headers: {'Range': 'bytes=0-512'},
        ),
      );
      return response.statusCode == 200 || response.statusCode == 206;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<MutualFundSearchResult>> searchSchemes(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    try {
      final response = await _dio.get<String>(
        '/spages/NAVAll.txt',
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode != 200 || response.data == null) {
        return [];
      }

      final results = <MutualFundSearchResult>[];
      final lines = response.data!.split('\n');

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || !trimmed.contains(';')) continue;

        final parts = trimmed.split(';');
        if (parts.length >= 6) {
          final schemeCode = int.tryParse(parts[0].trim());
          final schemeName = parts[3].trim();

          if (schemeCode != null && schemeName.toLowerCase().contains(clean)) {
            results.add(
              MutualFundSearchResult(
                schemeCode: schemeCode,
                schemeName: schemeName,
                planType: MutualFundSearchResult.detectPlanType(schemeName),
                optionType: MutualFundSearchResult.detectOptionType(schemeName),
              ),
            );
            if (results.length >= 50) break; // Sensible limit
          }
        }
      }
      return results;
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

    try {
      final response = await _dio.get<String>(
        '/spages/NAVAll.txt',
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode != 200 || response.data == null) {
        return null;
      }

      final lines = response.data!.split('\n');
      String currentFundHouse = '';

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        // Header detection for Fund House
        if (!trimmed.contains(';') &&
            trimmed.toLowerCase().contains('mutual fund')) {
          currentFundHouse = trimmed;
          continue;
        }

        if (trimmed.startsWith('$schemeCode;')) {
          final parts = trimmed.split(';');
          if (parts.length >= 8) {
            final name = parts[3].trim();
            final isin = parts[1].trim() != '-' ? parts[1].trim() : null;
            final navStr = parts[6].trim();
            final dateStr = parts[7].trim();

            final navRecord = NavRecord(
              date: NavRecord.parseNavDate(dateStr),
              navMicroPaise: FinancialPrecision.navStringToMicroPaise(navStr),
              rawNav: navStr,
            );

            return MutualFundSchemeDetail(
              schemeCode: schemeCode,
              schemeName: name,
              fundHouse: currentFundHouse.isNotEmpty ? currentFundHouse : null,
              isin: isin,
              planType: MutualFundSearchResult.detectPlanType(name),
              optionType: MutualFundSearchResult.detectOptionType(name),
              latestNav: navRecord,
              navHistory: [navRecord],
            );
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<NavRecord?> getLatestNav(int schemeCode) async {
    final detail = await getSchemeDetails(schemeCode);
    return detail?.latestNav;
  }
}
