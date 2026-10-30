import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for app theme mode (System, Light, Dark).
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});
