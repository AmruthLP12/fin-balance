import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../data/cas/cas_import_service.dart';
import '../../../data/cas/cas_parser.dart';
import '../../../data/cas/cas_pdf_text.dart';

/// Import mutual fund history from a CAMS + KFintech CAS PDF. Parsing happens
/// on the device; only the public AMFI NAV file is downloaded to match ISINs.
class CasImportScreen extends ConsumerStatefulWidget {
  const CasImportScreen({super.key});

  @override
  ConsumerState<CasImportScreen> createState() => _CasImportScreenState();
}

class _CasImportScreenState extends ConsumerState<CasImportScreen> {
  List<CasFolio>? _folios;
  Map<String, AmfiScheme> _schemes = {};
  DateTime? _periodStart;
  bool _busy = false;
  String? _error;
  String? _done;

  Future<void> _pick() async {
    final picked = await FilePicker.pickFile(
        type: FileType.custom, allowedExtensions: ['pdf']);
    final path = picked?.path;
    if (path == null) return;
    final bytes = await File(path).readAsBytes();
    setState(() {
      _busy = true;
      _error = null;
      _done = null;
      _folios = null;
    });
    try {
      String? password;
      String text;
      while (true) {
        try {
          text = casTextFromPdf(bytes, password: password);
          break;
        } on CasPasswordException {
          if (!mounted) return;
          password = await _askPassword(retry: password != null);
          if (password == null) {
            setState(() => _busy = false);
            return;
          }
        }
      }
      final folios = parseCasText(text);
      final start = casPeriodStart(text);
      if (folios.isEmpty || start == null) {
        throw const FormatException(
            'No mutual fund folios found. Is this a CAMS + KFintech CAS?');
      }
      final schemes = await CasImportService(ref.read(databaseProvider))
          .lookupIsins({for (final f in folios) f.isin});
      setState(() {
        _folios = folios;
        _schemes = schemes;
        _periodStart = start;
      });
    } catch (e) {
      setState(() => _error = e is FormatException
          ? e.message
          : 'Could not read the statement: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPassword({required bool retry}) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('PDF password'),
        content: TextField(
          controller: c,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            helperText: 'Used only to open the file on this device.',
            errorText: retry ? 'Wrong password' : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, c.text),
              child: const Text('Open')),
        ],
      ),
    );
  }

  bool _ok(CasFolio f) => f.reconciles && _schemes.containsKey(f.isin);

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final r = await CasImportService(ref.read(databaseProvider)).importFolios(
        profileId: ref.read(activeProfileIdProvider),
        folios: _folios!.where(_ok).toList(),
        schemes: _schemes,
        periodStart: _periodStart!,
      );
      setState(() {
        _folios = null;
        _done =
            'Imported ${r.imported} transactions into ${r.holdings} holdings'
            '${r.duplicates > 0 ? ' (${r.duplicates} already present, skipped)' : ''}.';
      });
    } catch (e) {
      setState(() => _error = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final folios = _folios;
    final okCount = folios?.where(_ok).length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Import from CAS PDF')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Text(
            'Pick your CAMS + KFintech Consolidated Account Statement. It is '
            'read on this device and imported into the active profile. Folios '
            'of the same fund are combined into one holding.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Select CAS PDF'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.liability)),
            ),
          if (_done != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child:
                  Text(_done!, style: const TextStyle(color: AppColors.asset)),
            ),
          if (folios != null) ...[
            const SizedBox(height: AppSpacing.md),
            for (final f in folios)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: FinCard(child: _folioTile(f)),
              ),
            FilledButton(
              onPressed: _busy || okCount == 0 ? null : _import,
              child: Text('Import $okCount of ${folios.length} folios'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _folioTile(CasFolio f) {
    final matched = _schemes[f.isin];
    final problems = [
      if (matched == null)
        'Scheme not found in AMFI list (ISIN ${f.isin}), skipped',
      if (!f.reconciles)
        'Units do not match the statement closing balance, skipped',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(matched?.name ?? f.schemeName, style: AppTypography.titleMedium),
        const SizedBox(height: 4),
        Text('Folio ${f.folio} • ${f.txns.length} transactions',
            style: AppTypography.bodySmall),
        Text(
            'Opening ${f.opening.toStringAsFixed(3)} → closing '
            '${f.closing.toStringAsFixed(3)} units • cost ₹${f.totalCost.toStringAsFixed(2)}',
            style: AppTypography.bodySmall),
        const SizedBox(height: 4),
        if (problems.isEmpty)
          const Text('✓ Reconciled with statement',
              style: TextStyle(color: AppColors.asset))
        else
          for (final p in problems)
            Text('⚠ $p', style: const TextStyle(color: AppColors.liability)),
      ],
    );
  }
}
