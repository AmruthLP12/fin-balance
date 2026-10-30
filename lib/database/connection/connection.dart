import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Connect to the SQLite database on device storage via drift_flutter.
QueryExecutor connect() {
  return driftDatabase(
    name: 'finbalance',
    native: const DriftNativeOptions(
      shareAcrossIsolates: true,
    ),
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
