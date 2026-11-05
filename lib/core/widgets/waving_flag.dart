import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Karnataka (Kannada) flag, yellow over red, gently waving.
/// Cheap by design: ~20 vertical strips, one repaint boundary, stills when animations are
/// disabled by the system (or [animationsEnabled] is false, as in tests).
class WavingFlag extends StatefulWidget {
  /// Global switch; tests turn it off so `pumpAndSettle` can settle.
  static bool animationsEnabled = true;

  final double width;

  const WavingFlag({super.key, this.width = 24});

  @override
  State<WavingFlag> createState() => _WavingFlagState();
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
      label: 'Karnataka flag',
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(w, w * 0.68),
          painter: _FlagPainter(_controller),
        ),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  final Animation<double> animation;

  _FlagPainter(this.animation) : super(repaint: animation);

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
    final bandH = (size.height - amp * 2) / 2;
    final paint = Paint();

    for (var i = 0; i < _strips; i++) {
      final t = i / _strips;
      // Wave grows away from the pole.
      final angle = t * 2 * math.pi * 1.2 - phase;
      final dy = amp + math.sin(angle) * amp * (0.25 + 0.75 * t);
      final left = poleW + i * stripW;

      paint.color = _yellow;
      canvas.drawRect(Rect.fromLTWH(left, dy, stripW + 0.6, bandH), paint);
      paint.color = _red;
      canvas.drawRect(
          Rect.fromLTWH(left, dy + bandH, stripW + 0.6, bandH), paint);

      // Light/shadow along the wave for depth.
      final shade = math.cos(angle) * 0.14;
      paint.color = (shade > 0 ? Colors.white : Colors.black)
          .withValues(alpha: shade.abs());
      canvas.drawRect(Rect.fromLTWH(left, dy, stripW + 0.6, bandH * 2), paint);
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
