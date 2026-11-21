import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/notifications/personal_debt_reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PersonalDebtReminderService.initialize();

  runApp(
    const ProviderScope(
      child: FinBalanceApp(),
    ),
  );
}
