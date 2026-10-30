import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/core/theme/app_colors.dart';
import 'package:finbalance/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('darkTheme has dark brightness and correct primary surface', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.darkBackground));
      expect(theme.colorScheme.primary, equals(AppColors.brandPrimary));
    });

    test('lightTheme has light brightness and correct primary surface', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.lightBackground));
      expect(theme.colorScheme.primary, equals(AppColors.brandPrimary));
    });
  });
}
