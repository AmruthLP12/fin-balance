import 'dart:async';
import 'package:finbalance/core/widgets/waving_flag.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // A repeating animation would keep pumpAndSettle from ever settling.
  WavingFlag.animationsEnabled = false;
  await testMain();
}
