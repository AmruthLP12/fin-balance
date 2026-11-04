import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the external browser; shows a SnackBar if it cannot be opened.
Future<void> openLink(BuildContext context, String url) async {
  var opened = false;
  try {
    opened =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open $url')),
    );
  }
}
