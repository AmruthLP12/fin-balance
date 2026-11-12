import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';
import 'nav_providers.dart';

/// Human readable outcome of the last automatic NAV refresh (shown in Settings).
final navAutoRefreshStatusProvider = StateProvider<String?>((ref) => null);

/// Keeps NAVs fresh without the user pressing anything: checks when the app
/// opens, every time it returns to the foreground, and at the next due time
/// while it stays open. When offline it retries after a few minutes.
/// (Android does not let an idle app run at 3:00 AM, so "due" means the first
/// moment the app is next opened or resumed after 3:00 AM.)
class NavAutoRefresh extends ConsumerStatefulWidget {
  /// Tests turn this off so no timers or network calls are started.
  static bool enabled = true;

  const NavAutoRefresh({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<NavAutoRefresh> createState() => _NavAutoRefreshState();
}

class _NavAutoRefreshState extends ConsumerState<NavAutoRefresh>
    with WidgetsBindingObserver {
  static const _retryAfter = Duration(minutes: 10);
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (!NavAutoRefresh.enabled || _running) return;
    _running = true;
    _timer?.cancel();
    final status = ref.read(navAutoRefreshStatusProvider.notifier);
    try {
      final settings = ref.read(appSettingsDaoProvider);
      final frequency =
          await settings.getSetting('nav_refresh_frequency') ?? 'daily';
      if (frequency == 'manual') return;
      final service = ref.read(navSyncServiceProvider);
      final summary = await service.syncAllPortfolioSchemes(
          force: false, frequency: frequency);
      final now = DateTime.now();
      if (summary.offline ||
          (summary.failedCount > 0 && summary.successCount == 0)) {
        status.state =
            'Auto-refresh failed at ${_hm(now)}: no internet connection or NAV service unreachable. Will retry.';
        _timer = Timer(_retryAfter, _check);
      } else {
        status.state = summary.failedCount > 0
            ? 'Auto-refresh at ${_hm(now)}: ${summary.successCount} updated, ${summary.failedCount} failed. Will retry.'
            : 'Auto-refresh checked at ${_hm(now)}.';
        final last = await service.getLastSuccessfulSyncTime();
        final next = summary.failedCount > 0
            ? now.add(_retryAfter)
            : service.getNextEligibleSync(last, frequency)?.toLocal();
        if (next != null) {
          final wait = next.difference(now);
          _timer = Timer(
              wait.isNegative ? _retryAfter : wait + const Duration(seconds: 5),
              _check);
        }
      }
    } catch (e) {
      status.state = 'Auto-refresh error: $e';
      _timer = Timer(_retryAfter, _check);
    } finally {
      _running = false;
    }
  }

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => widget.child;
}
