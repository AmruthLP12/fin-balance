import 'models/nav_models.dart';

/// Provider-independent interface for fetching Mutual Fund scheme and NAV information.
abstract class NavProvider {
  /// Unique identifier of the provider ('mfapi', 'tigzig', 'amfi')
  String get providerId;

  /// Display name of the provider
  String get providerName;

  /// Check whether the provider endpoint is currently accessible
  Future<bool> isAvailable();

  /// Search mutual fund schemes by name or keyword
  Future<List<MutualFundSearchResult>> searchSchemes(String query);

  /// Fetch full scheme details including metadata and latest/historical NAVs
  Future<MutualFundSchemeDetail?> getSchemeDetails(
    int schemeCode, {
    bool includeHistoricalNav = false,
  });

  /// Fetch only the latest NAV record for a scheme
  Future<NavRecord?> getLatestNav(int schemeCode);
}
