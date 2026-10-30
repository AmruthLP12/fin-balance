import 'package:flutter/material.dart';
import '../../../database/app_database.dart';

/// Reusable Profile Avatar widget supporting initials, relationship icons, and custom colors.
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

  @override
  Widget build(BuildContext context) {
    final effectiveName = profile?.name ?? name ?? 'User';
    final effectiveRel =
        (profile?.relationship ?? relationship ?? 'self').toLowerCase();
    final effectiveColor = _parseColor(profile?.colorHex ?? colorHex);

    final icon = _iconForRelationship(effectiveRel);
    final initial =
        effectiveName.isNotEmpty ? effectiveName[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: effectiveColor.withValues(alpha: 0.2),
      foregroundColor: effectiveColor,
      child: radius > 16
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: radius * 0.9, color: effectiveColor),
              ],
            )
          : Text(
              initial,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.9,
                color: effectiveColor,
              ),
            ),
    );
  }

  IconData _iconForRelationship(String rel) {
    switch (rel) {
      case 'father':
        return Icons.elderly_rounded;
      case 'mother':
        return Icons.elderly_woman_rounded;
      case 'spouse':
        return Icons.favorite_rounded;
      case 'child':
        return Icons.child_care_rounded;
      case 'self':
        return Icons.person_rounded;
      default:
        return Icons.account_circle_rounded;
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF10B981);
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      }
      if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return const Color(0xFF10B981);
  }
}
