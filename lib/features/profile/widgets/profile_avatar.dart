import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../database/app_database.dart';

/// Reusable Profile Avatar widget displaying the first letter of the profile name,
/// with consistent circular shape and distinct deterministic color palette.
class ProfileAvatar extends StatelessWidget {
  final FinancialProfile? profile;
  final String? name;
  final String? relationship;
  final String? colorHex;
  final double radius;

  const ProfileAvatar({
    super.key,
    this.profile,
    this.name,
    this.relationship,
    this.colorHex,
    this.radius = 20,
  });

  /// Factory constructor to render avatar for currently active profile.
  static Widget active({Key? key, double radius = 18}) {
    return _ActiveProfileAvatar(key: key, radius: radius);
  }

  static const List<Color> _palette = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF6366F1), // Indigo
    Color(0xFF14B8A6), // Teal
    Color(0xFFE11D48), // Rose
  ];

  @override
  Widget build(BuildContext context) {
    final effectiveName = profile?.name ?? name ?? 'User';
    final effectiveColor =
        _getColor(effectiveName, profile?.colorHex ?? colorHex);
    final initial = effectiveName.trim().isNotEmpty
        ? effectiveName.trim()[0].toUpperCase()
        : '?';

    final fontSize = radius * 0.95;

    return CircleAvatar(
      radius: radius,
      backgroundColor: effectiveColor.withValues(alpha: 0.18),
      foregroundColor: effectiveColor,
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          color: effectiveColor,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Color _getColor(String seedName, String? hex) {
    if (hex != null && hex.trim().isNotEmpty) {
      try {
        final clean = hex.replaceAll('#', '').trim();
        if (clean.length == 6) {
          return Color(int.parse('0xFF$clean'));
        }
        if (clean.length == 8) {
          return Color(int.parse('0x$clean'));
        }
      } catch (_) {}
    }
    // Deterministic palette selection based on name hash
    final hash = seedName.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    return _palette[hash % _palette.length];
  }
}

class _ActiveProfileAvatar extends ConsumerWidget {
  final double radius;

  const _ActiveProfileAvatar({super.key, required this.radius});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfileAsync = ref.watch(activeProfileProvider);
    final profile = activeProfileAsync.value;

    return ProfileAvatar(
      profile: profile,
      radius: radius,
    );
  }
}
