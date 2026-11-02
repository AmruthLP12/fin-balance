import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';

/// Top-left navigation action that returns to the initial Profile Selection screen.
///
/// Features:
/// - Clear, dedicated `switch_account_rounded` icon distinct from the standard back arrow.
/// - Returns user to the family profile selection screen without deleting or resetting the active profile.
/// - Does not trigger full database reconnection or application restart.
class ReturnToProfilesButton extends ConsumerWidget {
  const ReturnToProfilesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.switch_account_rounded),
      tooltip: 'Switch Profile / Select Family Member',
      onPressed: () {
        ref.read(hasSelectedInitialProfileProvider.notifier).state = false;
      },
    );
  }
}
