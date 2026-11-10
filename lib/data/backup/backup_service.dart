import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../../database/app_database.dart';

/// Exports every table to one JSON document and restores it. Rows are copied
/// as stored (ids, dates and money in their raw form), so a restore is exact.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const _app = 'FinBalance';

  Set<String> get _tables => {for (final t in _db.allTables) t.actualTableName};

  Future<Uint8List> export() async {
    final tables = <String, List<Map<String, Object?>>>{};
    for (final name in _tables) {
      final rows = await _db.customSelect('SELECT * FROM "$name"').get();
      tables[name] = [
        for (final r in rows)
          {
            for (final e in r.data.entries)
              e.key: e.value is Uint8List
                  ? {r'$b64': base64Encode(e.value as Uint8List)}
                  : e.value,
          }
      ];
    }
    return utf8.encode(jsonEncode({
      'app': _app,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'tables': tables,
    }));
  }

  /// Replaces ALL current data with the backup. Throws [FormatException] for
  /// files that are not a FinBalance backup (nothing is changed then).
  Future<int> restore(Uint8List bytes) async {
    final Map<String, dynamic> doc;
    try {
      doc = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('This is not a FinBalance backup file.');
    }
    if (doc['app'] != _app || doc['tables'] is! Map) {
      throw const FormatException('This is not a FinBalance backup file.');
    }
    if ((doc['schemaVersion'] as int? ?? 0) > _db.schemaVersion) {
      throw const FormatException(
          'This backup is from a newer version of FinBalance. Update the app first.');
    }
    final data = doc['tables'] as Map<String, dynamic>;
    final known = _tables;

    // Foreign keys are switched off for the bulk copy, then checked again.
    await _db.customStatement('PRAGMA foreign_keys = OFF');
    var count = 0;
    try {
      await _db.transaction(() async {
        for (final name in known) {
          await _db.customStatement('DELETE FROM "$name"');
        }
        for (final name in known) {
          final rows = data[name];
          if (rows is! List || rows.isEmpty) continue;
          final cols = {
            for (final c
                in await _db.customSelect('PRAGMA table_info("$name")').get())
              c.read<String>('name')
          };
          for (final row in rows.cast<Map<String, dynamic>>()) {
            // Only columns that exist in this app's table are written.
            final keys = row.keys.where(cols.contains).toList();
            await _db.customStatement(
              'INSERT INTO "$name" (${keys.map((k) => '"$k"').join(',')}) '
              'VALUES (${List.filled(keys.length, '?').join(',')})',
              [
                for (final k in keys)
                  row[k] is Map
                      ? base64Decode((row[k] as Map)[r'$b64'] as String)
                      : row[k]
              ],
            );
            count++;
          }
        }
        final bad = await _db.customSelect('PRAGMA foreign_key_check').get();
        if (bad.isNotEmpty) {
          throw const FormatException('The backup is inconsistent.');
        }
      });
    } finally {
      await _db.customStatement('PRAGMA foreign_keys = ON');
    }
    _db.markTablesUpdated(_db.allTables);
    return count;
  }
}
