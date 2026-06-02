import 'dart:math';

import 'package:flutter/material.dart';

class RadarAnimation extends StatefulWidget {
  const RadarAnimation({super.key});

  @override
  State<RadarAnimation> createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<RadarAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _DiscoveryPainter(_controller.value),
          size: const Size(double.infinity, 320),
        );
      },
    );
  }
}

class _DiscoveryPainter extends CustomPainter {
  final double progress;

  _DiscoveryPainter(this.progress);

  static const _pins = [
    _PinData(0.18, 0.24, Color(0xFFFF6B57), 1.0),
    _PinData(0.38, 0.36, Color(0xFF4C8DFF), 0.7),
    _PinData(0.70, 0.22, Color(0xFFFFB547), 0.4),
    _PinData(0.76, 0.58, Color(0xFF21A366), 0.9),
    _PinData(0.28, 0.67, Color(0xFF8B6CFF), 0.2),
    _PinData(0.57, 0.76, Color(0xFFFF7BA5), 0.55),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gridPaint = Paint()
      ..color = const Color(0x14000000)
      ..strokeWidth = 1;

    final routePaint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pulseCenter = Offset(
      size.width * (0.2 + 0.55 * progress),
      size.height * (0.28 + 0.18 * sin(progress * 2 * pi)),
    );

    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF7EF),
          Color(0xFFF1F8FF),
          Color(0xFFF8F2FF),
        ],
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(28)),
      backgroundPaint,
    );

    for (double x = 0; x <= size.width; x += size.width / 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += size.height / 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.40,
        size.width * 0.54,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.60,
        size.width * 0.82,
        size.height * 0.30,
      );
    canvas.drawPath(path, routePaint);

    for (final pin in _pins) {
      final center = Offset(size.width * pin.x, size.height * pin.y);
      final wave = 0.75 + 0.25 * sin((progress + pin.phase) * 2 * pi);

      final glowPaint = Paint()
        ..color = pin.color.withValues(alpha: 0.14 * wave)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 22 * wave, glowPaint);

      final pinPaint = Paint()..color = pin.color;
      canvas.drawCircle(center, 10, pinPaint);

      final innerPaint = Paint()..color = Colors.white;
      canvas.drawCircle(center, 4, innerPaint);
    }

    final focusPaint = Paint()
      ..color = const Color(0xFF111111).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(pulseCenter, 26 + (10 * sin(progress * 2 * pi).abs()), focusPaint);
    canvas.drawCircle(pulseCenter, 42 + (12 * sin(progress * 2 * pi).abs()), focusPaint);

    final scannerPaint = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(pulseCenter.dx - 18, pulseCenter.dy),
      Offset(pulseCenter.dx + 18, pulseCenter.dy),
      scannerPaint,
    );
    canvas.drawLine(
      Offset(pulseCenter.dx, pulseCenter.dy - 18),
      Offset(pulseCenter.dx, pulseCenter.dy + 18),
      scannerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DiscoveryPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _PinData {
  final double x;
  final double y;
  final Color color;
  final double phase;

  const _PinData(this.x, this.y, this.color, this.phase);
}
