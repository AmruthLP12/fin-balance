import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Karnataka (Kannada) flag, yellow over red, gently waving.
/// Cheap by design: ~20 vertical strips, one repaint boundary, stills when animations are
/// disabled by the system (or [animationsEnabled] is false, as in tests).
class WavingFlag extends StatefulWidget {
  /// Global switch; tests turn it off so `pumpAndSettle` can settle.
  static bool animationsEnabled = true;

  final double width;

  /// Draws the Indian tricolor (with chakra) instead of the Karnataka flag.
  final bool india;

  const WavingFlag({super.key, this.width = 24, this.india = false});

  @override
  State<WavingFlag> createState() => _WavingFlagState();
}

/// Indian tricolor, waving exactly like the Karnataka flag.
class IndianFlag extends WavingFlag {
  const IndianFlag({super.key, super.width}) : super(india: true);
}

class _WavingFlagState extends State<WavingFlag>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = WavingFlag.animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    return Semantics(
      label: widget.india ? 'Indian flag' : 'Karnataka flag',
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(w, w * 0.68),
          painter: _FlagPainter(_controller, widget.india),
        ),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  final Animation<double> animation;
  final bool india;

  _FlagPainter(this.animation, this.india) : super(repaint: animation);

  static const _yellow = Color(0xFFFFCC00);
  static const _red = Color(0xFFE31E24);
  static const _strips = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = animation.value * 2 * math.pi;
    final poleW = size.width * 0.07;
    final clothW = size.width - poleW;
    final amp = size.height * 0.09;
    final stripW = clothW / _strips;
    final colors = india
        ? const [Color(0xFFFF9933), Colors.white, Color(0xFF138808)]
        : const [_yellow, _red];
    final bandH = (size.height - amp * 2) / colors.length;
    final paint = Paint();

    for (var i = 0; i < _strips; i++) {
      final t = i / _strips;
      // Wave grows away from the pole.
      final angle = t * 2 * math.pi * 1.2 - phase;
      final dy = amp + math.sin(angle) * amp * (0.25 + 0.75 * t);
      final left = poleW + i * stripW;

      for (var b = 0; b < colors.length; b++) {
        paint.color = colors[b];
        canvas.drawRect(
            Rect.fromLTWH(left, dy + bandH * b, stripW + 0.6, bandH), paint);
      }

      // Light/shadow along the wave for depth.
      final shade = math.cos(angle) * 0.14;
      paint.color = (shade > 0 ? Colors.white : Colors.black)
          .withValues(alpha: shade.abs());
      canvas.drawRect(
          Rect.fromLTWH(left, dy, stripW + 0.6, bandH * colors.length), paint);
    }

    if (india) {
      // Ashoka chakra rides the wave at the middle of the cloth.
      const t = 0.5;
      final angle = t * 2 * math.pi * 1.2 - phase;
      final dy = amp + math.sin(angle) * amp * (0.25 + 0.75 * t);
      final center = Offset(poleW + clothW / 2, dy + bandH * 1.5);
      final r = bandH * 0.42;
      paint
        ..color = const Color(0xFF000080)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.03;
      canvas.drawCircle(center, r, paint);
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6;
        canvas.drawLine(
            center, center + Offset(math.cos(a), math.sin(a)) * r, paint);
      }
      paint.style = PaintingStyle.fill;
    }

    paint.color = const Color(0xFF9CA3AF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, poleW, size.height), Radius.circular(poleW)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_FlagPainter old) => false;
}
