import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/nav_auto_refresh.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/screens/main_scaffold.dart';
import 'features/profile/screens/profile_selection_screen.dart';

/// Root application widget for FinBalance.
class FinBalanceApp extends ConsumerWidget {
  const FinBalanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final hasSelectedProfile = ref.watch(hasSelectedInitialProfileProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) => NavAutoRefresh(child: child!),
      home: hasSelectedProfile
          ? const MainScaffold()
          : const ProfileSelectionScreen(),
    );
  }
}
