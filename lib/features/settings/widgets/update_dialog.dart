import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../data/update/update_service.dart';

const updateLastCheckedKey = 'update_last_checked';

/// Checks for an update and shows the dialog. [silent] suppresses
/// "up to date" / error feedback (used for the automatic launch check).
Future<void> checkForUpdates(BuildContext context, WidgetRef ref,
    {bool silent = false}) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String m) {
    if (!silent) messenger.showSnackBar(SnackBar(content: Text(m)));
  }

  try {
    final update = await UpdateService().checkForUpdate();
    await ref
        .read(appSettingsDaoProvider)
        .setSetting(updateLastCheckedKey, DateTime.now().toIso8601String());
    if (update == null) return say('You are on the latest version.');
    if (context.mounted) await showUpdateDialog(context, update);
  } catch (_) {
    say('Could not check for updates. Check your connection.');
  }
}

/// Shows the "new version" dialog; downloads and installs on confirm.
Future<void> showUpdateDialog(BuildContext context, AppUpdate update) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDialog(update: update),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.update});
  final AppUpdate update;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress;
  String? _error;

  Future<void> _install() async {
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      await UpdateService().downloadAndInstall(
        widget.update,
        (p) => mounted ? setState(() => _progress = p) : null,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _progress = null;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.update;
    final downloading = _progress != null;
    return AlertDialog(
      title: Text('Update available: v${u.version}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size: ${(u.sizeBytes / 1048576).toStringAsFixed(1)} MB'),
            if (u.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(u.notes),
            ],
            if (downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 4),
              Text('Downloading ${(_progress! * 100).round()}%'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: downloading ? null : () => Navigator.pop(context),
          child: const Text('Remind me later'),
        ),
        FilledButton(
          onPressed: downloading ? null : _install,
          child: Text(_error == null ? 'Download & install' : 'Retry'),
        ),
      ],
    );
  }
}
