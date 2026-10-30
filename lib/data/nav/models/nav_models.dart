import '../../../database/precision/financial_precision.dart';

/// Search summary item from a mutual fund provider.
class MutualFundSearchResult {
  final int schemeCode;
  final String schemeName;
  final String? fundHouse;
  final String planType;
  final String optionType;

  const MutualFundSearchResult({
    required this.schemeCode,
    required this.schemeName,
    this.fundHouse,
    required this.planType,
    required this.optionType,
  });

  factory MutualFundSearchResult.fromJson(Map<String, dynamic> json) {
    final code = json['schemeCode'] is int
        ? json['schemeCode'] as int
        : int.tryParse(json['schemeCode']?.toString() ?? '') ?? 0;
    final name = json['schemeName']?.toString() ?? '';

    return MutualFundSearchResult(
      schemeCode: code,
      schemeName: name,
      fundHouse: json['fundHouse']?.toString(),
      planType: detectPlanType(name),
      optionType: detectOptionType(name),
    );
  }

  static String detectPlanType(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('direct')) return 'Direct';
    if (lower.contains('regular')) return 'Regular';
    return 'Regular';
  }

  static String detectOptionType(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('growth') || lower.contains('- gr')) return 'Growth';
    if (lower.contains('idcw') ||
        lower.contains('dividend') ||
        lower.contains('- div')) {
      return 'IDCW';
    }
    return 'Growth';
  }
}

/// A single NAV datapoint for a specific date.
class NavRecord {
  final DateTime date;
  final int navMicroPaise;
  final String? rawNav;

  const NavRecord({
    required this.date,
    required this.navMicroPaise,
    this.rawNav,
  });

  factory NavRecord.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date']?.toString() ?? '';
    final rawNav = json['nav']?.toString() ?? '0';

    return NavRecord(
      date: parseNavDate(rawDate),
      navMicroPaise: FinancialPrecision.navStringToMicroPaise(rawNav),
      rawNav: rawNav,
    );
  }

  /// Parse dates in DD-MM-YYYY, DD-MMM-YYYY, or YYYY-MM-DD format.
  static DateTime parseNavDate(String dateStr) {
    final clean = dateStr.trim();
    if (clean.isEmpty) return DateTime.utc(1970, 1, 1);

    // 1. DD-MM-YYYY format (e.g. "29-10-2026")
    final dashParts = clean.split('-');
    if (dashParts.length == 3) {
      if (dashParts[0].length <= 2 && dashParts[2].length == 4) {
        final day = int.tryParse(dashParts[0]) ?? 1;
        final year = int.tryParse(dashParts[2]) ?? 1970;

        // Check if month is numeric or month name (Oct)
        final monthNum = int.tryParse(dashParts[1]);
        if (monthNum != null) {
          return DateTime.utc(year, monthNum, day);
        } else {
          final month = _parseMonthName(dashParts[1]);
          return DateTime.utc(year, month, day);
        }
      } else if (dashParts[0].length == 4) {
        // YYYY-MM-DD
        final year = int.tryParse(dashParts[0]) ?? 1970;
        final month = int.tryParse(dashParts[1]) ?? 1;
        final day = int.tryParse(dashParts[2]) ?? 1;
        return DateTime.utc(year, month, day);
      }
    }

    return DateTime.tryParse(clean)?.toUtc() ?? DateTime.utc(1970, 1, 1);
  }

  static int _parseMonthName(String monthStr) {
    switch (monthStr.trim().toLowerCase()) {
      case 'jan':
        return 1;
      case 'feb':
        return 2;
      case 'mar':
        return 3;
      case 'apr':
        return 4;
      case 'may':
        return 5;
      case 'jun':
        return 6;
      case 'jul':
        return 7;
      case 'aug':
        return 8;
      case 'sep':
        return 9;
      case 'oct':
        return 10;
      case 'nov':
        return 11;
      case 'dec':
        return 12;
      default:
        return 1;
    }
  }
}

/// Detailed mutual fund scheme information with latest and historical NAVs.
class MutualFundSchemeDetail {
  final int schemeCode;
  final String schemeName;
  final String? fundHouse;
  final String? schemeType;
  final String? schemeCategory;
  final String? isin;
  final String planType;
  final String optionType;
  final NavRecord? latestNav;
  final List<NavRecord> navHistory;

  const MutualFundSchemeDetail({
    required this.schemeCode,
    required this.schemeName,
    this.fundHouse,
    this.schemeType,
    this.schemeCategory,
    this.isin,
    required this.planType,
    required this.optionType,
    this.latestNav,
    this.navHistory = const [],
  });

  factory MutualFundSchemeDetail.fromMfApiJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final schemeCode = meta['scheme_code'] is int
        ? meta['scheme_code'] as int
        : int.tryParse(meta['scheme_code']?.toString() ?? '') ?? 0;
    final schemeName = meta['scheme_name']?.toString() ?? '';

    final dataList = json['data'] as List<dynamic>? ?? [];
    final records = dataList
        .whereType<Map<String, dynamic>>()
        .map((d) => NavRecord.fromJson(d))
        .toList();

    return MutualFundSchemeDetail(
      schemeCode: schemeCode,
      schemeName: schemeName,
      fundHouse: meta['fund_house']?.toString(),
      schemeType: meta['scheme_type']?.toString(),
      schemeCategory: meta['scheme_category']?.toString(),
      isin: meta['isin_growth']?.toString() ??
          meta['isin_div_reinvestment']?.toString(),
      planType: MutualFundSearchResult.detectPlanType(schemeName),
      optionType: MutualFundSearchResult.detectOptionType(schemeName),
      latestNav: records.isNotEmpty ? records.first : null,
      navHistory: records,
    );
  }
}
