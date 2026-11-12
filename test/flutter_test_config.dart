import 'dart:async';
import 'package:finbalance/core/providers/nav_auto_refresh.dart';
import 'package:finbalance/core/widgets/waving_flag.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // A repeating animation would keep pumpAndSettle from ever settling.
  WavingFlag.animationsEnabled = false;
  NavAutoRefresh.enabled = false;
  await testMain();
}
