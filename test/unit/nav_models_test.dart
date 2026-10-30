import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/data/nav/models/nav_models.dart';
import 'package:finbalance/database/precision/financial_precision.dart';

void main() {
  group('MutualFundSearchResult Model & Heuristics', () {
    test('detects Direct vs Regular plans accurately', () {
      expect(
        MutualFundSearchResult.detectPlanType(
            'SBI SMALL CAP FUND - Direct Plan - Growth'),
        equals('Direct'),
      );
      expect(
        MutualFundSearchResult.detectPlanType(
            'HDFC Mid-Cap Opportunities Fund - Regular Plan - Growth'),
        equals('Regular'),
      );
      expect(
        MutualFundSearchResult.detectPlanType(
            'Nippon India Small Cap Fund - Growth'),
        equals('Regular'), // Default fallback
      );
    });

    test('detects Growth vs IDCW options accurately', () {
      expect(
        MutualFundSearchResult.detectOptionType(
            'Parag Parikh Flexi Cap Fund - Direct Plan - Growth'),
        equals('Growth'),
      );
      expect(
        MutualFundSearchResult.detectOptionType(
            'Axis Bluechip Fund - Direct Plan - IDCW'),
        equals('IDCW'),
      );
      expect(
        MutualFundSearchResult.detectOptionType(
            'UTI Nifty 50 Index Fund - Regular - Dividend Reinvestment'),
        equals('IDCW'),
      );
      expect(
        MutualFundSearchResult.detectOptionType(
            'ICICI Prudential Value Discovery Fund - Gr'),
        equals('Growth'),
      );
    });
  });

  group('NavRecord Date & Precision Parsing', () {
    test('parses DD-MM-YYYY dates correctly', () {
      final date = NavRecord.parseNavDate('29-10-2026');
      expect(date.year, equals(2026));
      expect(date.month, equals(10));
      expect(date.day, equals(29));
    });

    test('parses DD-MMM-YYYY dates correctly (AMFI format)', () {
      final date = NavRecord.parseNavDate('29-Oct-2026');
      expect(date.year, equals(2026));
      expect(date.month, equals(10));
      expect(date.day, equals(29));

      final janDate = NavRecord.parseNavDate('15-Jan-2025');
      expect(janDate.month, equals(1));
      expect(janDate.day, equals(15));
    });

    test('parses YYYY-MM-DD dates correctly', () {
      final date = NavRecord.parseNavDate('2026-10-29');
      expect(date.year, equals(2026));
      expect(date.month, equals(10));
      expect(date.day, equals(29));
    });

    test(
        'navStringToMicroPaise converts raw decimal strings without float drift',
        () {
      // 1 Rupee = 1,000,000 micro-paise
      expect(
        FinancialPrecision.navStringToMicroPaise('200.18460'),
        equals(200184600),
      );
      expect(
        FinancialPrecision.navStringToMicroPaise('125.4560'),
        equals(125456000),
      );
      expect(
        FinancialPrecision.navStringToMicroPaise('10.00'),
        equals(10000000),
      );
      expect(
        FinancialPrecision.navStringToMicroPaise('0.5'),
        equals(500000),
      );
      expect(
        FinancialPrecision.navStringToMicroPaise(''),
        equals(0),
      );
      expect(
        FinancialPrecision.navStringToMicroPaise(null),
        equals(0),
      );
    });
  });

  group('MutualFundSchemeDetail Parsing', () {
    test('parses complete MFapi response JSON', () {
      final json = {
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
          {'date': '28-10-2026', 'nav': '199.50000'},
        ],
        'status': 'SUCCESS',
      };

      final detail = MutualFundSchemeDetail.fromMfApiJson(json);
      expect(detail.schemeCode, equals(125497));
      expect(detail.schemeName,
          equals('SBI SMALL CAP FUND - Direct Plan - Growth'));
      expect(detail.fundHouse, equals('SBI Mutual Fund'));
      expect(detail.schemeCategory, equals('Equity Scheme - Small Cap Fund'));
      expect(detail.isin, equals('INF200K01T51'));
      expect(detail.planType, equals('Direct'));
      expect(detail.optionType, equals('Growth'));
      expect(detail.latestNav, isNotNull);
      expect(detail.latestNav!.navMicroPaise, equals(200184600));
      expect(detail.navHistory.length, equals(2));
    });

    test('handles missing metadata and empty data gracefully', () {
      final json = {
        'meta': {
          'scheme_code': 100001,
          'scheme_name': 'Incomplete Scheme',
        },
        'data': <Map<String, dynamic>>[],
        'status': 'SUCCESS',
      };

      final detail = MutualFundSchemeDetail.fromMfApiJson(json);
      expect(detail.schemeCode, equals(100001));
      expect(detail.schemeName, equals('Incomplete Scheme'));
      expect(detail.fundHouse, isNull);
      expect(detail.latestNav, isNull);
      expect(detail.navHistory, isEmpty);
    });
  });
}
