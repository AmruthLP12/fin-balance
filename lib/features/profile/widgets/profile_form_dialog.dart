import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../database/app_database.dart';
import 'profile_avatar.dart';

/// Dialog for creating or editing a financial profile.
class ProfileFormDialog extends ConsumerStatefulWidget {
  final FinancialProfile? profileToEdit;

  const ProfileFormDialog({super.key, this.profileToEdit});

  @override
  ConsumerState<ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends ConsumerState<ProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedRelationship;
  late String _selectedColorHex;
  late bool _isDefault;
  bool _isSaving = false;

  static const List<Map<String, String>> _relationships = [
    {'value': 'self', 'label': 'Self'},
    {'value': 'spouse', 'label': 'Spouse'},
    {'value': 'father', 'label': 'Father'},
    {'value': 'mother', 'label': 'Mother'},
    {'value': 'child', 'label': 'Child'},
    {'value': 'other', 'label': 'Other'},
  ];

  static const List<String> _palette = [
    '#10B981', // Emerald
    '#3B82F6', // Blue
    '#8B5CF6', // Purple
    '#F59E0B', // Amber
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#6366F1', // Indigo
    '#14B8A6', // Teal
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profileToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _selectedRelationship = p?.relationship ?? 'self';
    _selectedColorHex = p?.colorHex ?? '#10B981';
    _isDefault = p?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.profileToEdit != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Profile' : 'Create New Profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Avatar
              Center(
                child: ProfileAvatar(
                  name: _nameController.text.isEmpty
                      ? 'User'
                      : _nameController.text,
                  relationship: _selectedRelationship,
                  colorHex: _selectedColorHex,
                  radius: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Profile / Person Name *',
                  hintText: 'e.g. Papa, Priya, Aarav',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a profile name';
                  }
                  if (val.trim().length > 100) {
                    return 'Name cannot exceed 100 characters';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),

              // Relationship Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedRelationship,
                decoration: const InputDecoration(
                  labelText: 'Relationship *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people_outline_rounded),
                ),
                items: _relationships
                    .map((r) => DropdownMenuItem(
                          value: r['value'],
                          child: Text(r['label']!),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedRelationship = val);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Color Palette Selector
              Text(
                'Avatar Color',
                style: AppTypography.labelMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _palette.map((hex) {
                  final color =
                      Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
                  final isSelected =
                      _selectedColorHex.toUpperCase() == hex.toUpperCase();
                  return InkWell(
                    onTap: () => setState(() => _selectedColorHex = hex),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // Description (Optional)
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description / Notes (Optional)',
                  hintText: 'e.g. Retirement portfolio, Education fund',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Default profile toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as Default Profile',
                    style: AppTypography.bodyMedium),
                subtitle: const Text(
                  'Opens automatically on application launch',
                  style: AppTypography.labelSmall,
                ),
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveProfile,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Save Changes' : 'Create Profile'),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final dao = ref.read(profilesDaoProvider);

    try {
      final name = _nameController.text.trim();
      final desc = _descController.text.trim();

      if (widget.profileToEdit != null) {
        final existing = widget.profileToEdit!;
        await dao.updateProfile(
          FinancialProfilesCompanion(
            id: drift.Value(existing.id),
            name: drift.Value(name),
            relationship: drift.Value(_selectedRelationship),
            colorHex: drift.Value(_selectedColorHex),
            description: drift.Value(desc.isEmpty ? null : desc),
            isDefault: drift.Value(_isDefault),
            updatedAt: drift.Value(DateTime.now().toUtc()),
          ),
        );
      } else {
        final newId = await dao.createProfile(
          FinancialProfilesCompanion(
            name: drift.Value(name),
            relationship: drift.Value(_selectedRelationship),
            colorHex: drift.Value(_selectedColorHex),
            description: drift.Value(desc.isEmpty ? null : desc),
            isDefault: drift.Value(_isDefault),
          ),
        );
        // Switch to the newly created profile immediately
        await ref.read(activeProfileIdProvider.notifier).switchProfile(newId);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.profileToEdit != null
                  ? 'Profile updated successfully'
                  : 'Profile "$name" created and activated!',
            ),
            backgroundColor: AppColors.asset,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
