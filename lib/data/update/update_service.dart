import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// A newer release published on GitHub.
class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.notes,
    required this.apkUrl,
    required this.sizeBytes,
  });

  final String version;
  final String notes;
  final String apkUrl;
  final int sizeBytes;
}

/// True when [latest] ("v0.20.0" or "0.20.0") is newer than [current].
bool isNewerVersion(String latest, String current) {
  List<int> parse(String v) => v
      .replaceFirst(RegExp(r'^v'), '')
      .split('+')
      .first
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final a = parse(latest), b = parse(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

/// Checks GitHub Releases for a newer APK and downloads/installs it.
class UpdateService {
  UpdateService({Dio? dio}) : _dio = dio ?? Dio();

  static const String repo = 'AmruthLP12/fin-balance';
  final Dio _dio;

  /// Returns the newer release, or null when up to date. Throws on network errors.
  Future<AppUpdate?> checkForUpdate() async {
    final current = (await PackageInfo.fromPlatform()).version;
    final res = await _dio.get<Map<String, dynamic>>(
      'https://api.github.com/repos/$repo/releases/latest',
      options: Options(
        headers: {'Accept': 'application/vnd.github+json'},
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    final data = res.data!;
    final tag = data['tag_name'] as String;
    if (!isNewerVersion(tag, current)) return null;
    final assets = (data['assets'] as List).cast<Map<String, dynamic>>();
    final apk = assets.where((a) => (a['name'] as String).endsWith('.apk'));
    if (apk.isEmpty) return null;
    return AppUpdate(
      version: tag.replaceFirst(RegExp(r'^v'), ''),
      notes: (data['body'] as String?)?.trim() ?? '',
      apkUrl: apk.first['browser_download_url'] as String,
      sizeBytes: apk.first['size'] as int,
    );
  }

  /// Downloads the APK then opens Android's package installer.
  Future<void> downloadAndInstall(
    AppUpdate update,
    void Function(double progress) onProgress,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/finbalance_${update.version}.apk');
    await _dio.download(
      update.apkUrl,
      file.path,
      onReceiveProgress: (got, total) {
        final t = total > 0 ? total : update.sizeBytes;
        if (t > 0) onProgress((got / t).clamp(0, 1));
      },
    );
    if (await file.length() != update.sizeBytes) {
      await file.delete();
      throw Exception('Download incomplete, please try again.');
    }
    final r = await OpenFilex.open(file.path,
        type: 'application/vnd.android.package-archive');
    if (r.type != ResultType.done) throw Exception(r.message);
  }
}
