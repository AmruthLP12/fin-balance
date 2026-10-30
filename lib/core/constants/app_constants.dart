class AppConstants {
  AppConstants._();

  static const String appName = 'FinBalance';
  static const String appTagline = 'Personal Wealth & Net Worth Tracker';
  static const String appVersion = '1.0.0';

  // Currency
  static const String defaultCurrencySymbol = '₹';
  static const String defaultCurrencyCode = 'INR';

  // Synchronization Defaults
  static const int defaultNavRefreshHours = 24;
  static const int networkTimeoutSeconds = 10;

  // Storage Keys
  static const String themePreferenceKey = 'finbalance_theme_mode';
  static const String currencyPreferenceKey = 'finbalance_currency';
  static const String lastSyncTimestampKey = 'finbalance_last_sync_time';
}
