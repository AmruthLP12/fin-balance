import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';

/// StateNotifier managing and persisting ThemeMode using AppSettingsDao.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;

  ThemeModeNotifier(this._ref) : super(ThemeMode.system) {
    loadPersistedTheme();
  }

  Future<void> loadPersistedTheme() async {
    try {
      final db = _ref.read(databaseProvider);
      final savedTheme = await db.appSettingsDao.getSetting('theme_mode');
      if (savedTheme != null) {
        state = _parseThemeMode(savedTheme);
      }
    } catch (_) {
      // Retain system default if DB is not initialized or during isolated widget tests
    }
  }

  static ThemeMode _parseThemeMode(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final db = _ref.read(databaseProvider);
      await db.appSettingsDao
          .setSetting('theme_mode', _themeModeToString(mode));
    } catch (_) {}
  }
}

/// Provider for app theme mode (System, Light, Dark) backed by SQLite persistence.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});
