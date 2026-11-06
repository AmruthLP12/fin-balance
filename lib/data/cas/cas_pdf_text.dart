import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Thrown when the PDF needs a password (or the given one is wrong).
class CasPasswordException implements Exception {}

/// Extracts the text of a CAS PDF with rows rebuilt left-to-right by position,
/// so table rows come out as `date  description  amount  units  price  balance`.
/// Everything runs on the device.
String casTextFromPdf(Uint8List bytes, {String? password}) {
  final PdfDocument doc;
  try {
    doc = PdfDocument(inputBytes: bytes, password: password);
  } catch (_) {
    throw CasPasswordException();
  }
  try {
    final out = StringBuffer();
    for (var p = 0; p < doc.pages.count; p++) {
      final words = <TextWord>[
        for (final l in PdfTextExtractor(doc)
            .extractTextLines(startPageIndex: p, endPageIndex: p))
          ...l.wordCollection,
      ]..sort((a, b) => a.bounds.center.dy.compareTo(b.bounds.center.dy));
      // Group words whose vertical centres are within 3pt into one row.
      final rows = <List<TextWord>>[];
      for (final w in words) {
        if (rows.isNotEmpty &&
            (w.bounds.center.dy - rows.last.first.bounds.center.dy).abs() < 3) {
          rows.last.add(w);
        } else {
          rows.add([w]);
        }
      }
      for (final r in rows) {
        r.sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
        out.writeln(r.map((w) => w.text).join(' '));
      }
    }
    return out.toString();
  } finally {
    doc.dispose();
  }
}
