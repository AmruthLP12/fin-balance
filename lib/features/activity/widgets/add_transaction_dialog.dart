import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';

/// Full-screen mobile-optimized dialog for recording Income, Expense, or Transfer transactions.
class AddTransactionDialog extends ConsumerStatefulWidget {
  final String initialType;
  final int? preselectedProfileId;

  const AddTransactionDialog({
    super.key,
    this.initialType = 'expense',
    this.preselectedProfileId,
  });

  static Future<void> show(
    BuildContext context, {
    String initialType = 'expense',
    int? preselectedProfileId,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddTransactionDialog(
          initialType: initialType,
          preselectedProfileId: preselectedProfileId,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _transactionType;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _transactionDate;

  int? _selectedCategoryId;
  int? _selectedProfileId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialType;
    _amountController = TextEditingController();
    _notesController = TextEditingController();

    final now = DateTime.now();
    _transactionDate = DateTime(now.year, now.month, now.day);
    _selectedProfileId = widget.preselectedProfileId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profilesAsync = ref.watch(allProfilesProvider);
    final activeProfileId = ref.watch(activeProfileIdProvider);

    _selectedProfileId ??= activeProfileId;

    final typeCategory = _transactionType == 'income' ? 'income' : 'expense';
    final categoriesAsync = ref.watch(categoriesForProfileProvider((
      profileId: _selectedProfileId,
      classification: typeCategory,
    )));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          _transactionType == 'income'
              ? 'Add Income'
              : (_transactionType == 'transfer'
                  ? 'Record Transfer'
                  : 'Add Expense'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveTransaction,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
              style: FilledButton.styleFrom(
                backgroundColor: _transactionType == 'income'
                    ? AppColors.asset
                    : (_transactionType == 'transfer'
                        ? AppColors.brandPrimary
                        : AppColors.liability),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                children: [
                  // Type Selector
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'expense',
                        label: Text('Expense'),
                        icon: Icon(Icons.arrow_upward_rounded),
                      ),
                      ButtonSegment(
                        value: 'income',
                        label: Text('Income'),
                        icon: Icon(Icons.arrow_downward_rounded),
                      ),
                      ButtonSegment(
                        value: 'transfer',
                        label: Text('Transfer'),
                        icon: Icon(Icons.swap_horiz_rounded),
                      ),
                    ],
                    selected: {_transactionType},
                    onSelectionChanged: (set) {
                      setState(() {
                        _transactionType = set.first;
                        _selectedCategoryId = null;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Amount
                  Text(
                    'Transaction Amount',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      border: const OutlineInputBorder(),
                      hintText: 'e.g. 1500',
                      prefixStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _transactionType == 'income'
                            ? AppColors.asset
                            : (_transactionType == 'transfer'
                                ? AppColors.brandPrimaryLight
                                : AppColors.liability),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter amount';
                      }
                      final n = double.tryParse(val.trim());
                      if (n == null || n <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Category
                  if (_transactionType != 'transfer') ...[
                    Text(
                      'Category',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    categoriesAsync.when(
                      data: (cats) {
                        if (cats.isNotEmpty && _selectedCategoryId == null) {
                          _selectedCategoryId = cats.first.id;
                        }
                        return DropdownButtonFormField<int>(
                          initialValue: _selectedCategoryId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                          ),
                          items: cats
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategoryId = val);
                            }
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading categories'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Profile
                  Text(
                    'Profile',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  profilesAsync.when(
                    data: (profiles) => DropdownButtonFormField<int>(
                      initialValue: _selectedProfileId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      items: profiles
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.name} (${p.relationship})',
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedProfileId = val);
                        }
                      },
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error loading profiles'),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Transaction Date
                  Text(
                    'Transaction Date',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _transactionDate,
                        firstDate: DateTime(1990),
                        lastDate: DateTime(2040),
                      );
                      if (picked != null) {
                        setState(() => _transactionDate =
                            DateTime(picked.year, picked.month, picked.day));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormatter.formatDate(_transactionDate),
                            style: AppTypography.bodyMedium,
                          ),
                          const Icon(Icons.calendar_today_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Description / Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Description / Notes (Optional)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Monthly salary, Grocery shopping',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = _selectedProfileId;
    if (profileId == null) return;

    final amountRupees = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final amountPaise = FinancialPrecision.rupeesToPaise(amountRupees);
    final notes = _notesController.text.trim();

    setState(() => _isSaving = true);

    try {
      final db = ref.read(databaseProvider);

      // Default category if none selected
      int catId = _selectedCategoryId ?? 1;
      if (_transactionType == 'transfer') {
        final expCats =
            await db.categoriesDao.getCategoriesByClassification('expense');
        catId = expCats.isNotEmpty ? expCats.first.id : 1;
      }

      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: drift.Value(profileId),
          transactionType: drift.Value(_transactionType),
          categoryId: drift.Value(catId),
          transactionDate: drift.Value(_transactionDate),
          amountPaise: drift.Value(amountPaise),
          source: const drift.Value('manual'),
          notes: notes.isNotEmpty
              ? drift.Value(notes)
              : drift.Value(_transactionType.toUpperCase()),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recorded ${_transactionType.toUpperCase()} of ${CurrencyFormatter.formatPaise(amountPaise)}!',
            ),
            backgroundColor: _transactionType == 'income'
                ? AppColors.asset
                : (_transactionType == 'transfer'
                    ? AppColors.brandPrimary
                    : AppColors.liability),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record transaction: $e'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
