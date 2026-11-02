import 'dart:convert';
import 'dart:io';
import 'package:finbalance/core/widgets/finbalance_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Branding Assets & Logo Verification Tests', () {
    test('All Android launcher mipmap PNGs exist and have valid file sizes',
        () {
      final densities = [
        'mipmap-mdpi',
        'mipmap-hdpi',
        'mipmap-xhdpi',
        'mipmap-xxhdpi',
        'mipmap-xxxhdpi',
      ];

      for (final density in densities) {
        final file = File('android/app/src/main/res/$density/ic_launcher.png');
        expect(file.existsSync(), isTrue, reason: 'Missing icon for $density');
        expect(file.lengthSync(), greaterThan(100),
            reason: 'Icon for $density is unexpectedly small or empty');
      }
    });

    test('Adaptive launcher vector drawables exist and contain balanced colors',
        () {
      final fg =
          File('android/app/src/main/res/drawable/ic_launcher_foreground.xml');
      final bg =
          File('android/app/src/main/res/drawable/ic_launcher_background.xml');

      expect(fg.existsSync(), isTrue);
      expect(bg.existsSync(), isTrue);

      final fgContent = fg.readAsStringSync();
      expect(fgContent.contains('#10B981'), isTrue,
          reason: 'Foreground must contain Assets Emerald Green');
      expect(fgContent.contains('#2563EB'), isTrue,
          reason: 'Foreground must contain Liabilities Cobalt Blue');
      expect(fgContent.contains('#F59E0B'), isTrue,
          reason: 'Foreground must contain Net Worth Balance Golden Amber');
    });

    test(
        'Web icons, favicon, and manifest exist and contain FinBalance identity',
        () {
      final fav = File('web/favicon.png');
      expect(fav.existsSync(), isTrue);
      expect(fav.lengthSync(), greaterThan(50));

      final icon192 = File('web/icons/Icon-192.png');
      final icon512 = File('web/icons/Icon-512.png');
      final mask192 = File('web/icons/Icon-maskable-192.png');
      final mask512 = File('web/icons/Icon-maskable-512.png');

      expect(icon192.existsSync(), isTrue);
      expect(icon512.existsSync(), isTrue);
      expect(mask192.existsSync(), isTrue);
      expect(mask512.existsSync(), isTrue);

      final manifest = File('web/manifest.json');
      expect(manifest.existsSync(), isTrue);
      final manifestJson =
          jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>;
      expect(manifestJson['name'], contains('FinBalance'));
      expect(manifestJson['short_name'], equals('FinBalance'));
    });

    testWidgets('FinBalanceLogo renders correctly with text and tagline',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FinBalanceLogo(
              size: 48,
              showText: true,
              showTagline: true,
            ),
          ),
        ),
      );

      expect(find.text('Fin'), findsOneWidget);
      expect(find.text('Balance'), findsOneWidget);
      expect(find.text('Assets • Liabilities • Balance'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('FinBalanceLogo adapts cleanly to dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: FinBalanceLogo(
              size: 32,
              showText: true,
              showTagline: false,
            ),
          ),
        ),
      );

      expect(find.text('Fin'), findsOneWidget);
      expect(find.text('Balance'), findsOneWidget);
    });
  });
}
