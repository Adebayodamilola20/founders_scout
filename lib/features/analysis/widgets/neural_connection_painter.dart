import 'dart:math' as math;

import 'package:flutter/material.dart';

class _NeuralNode {
  final Offset anchor;
  final double orbitX;
  final double orbitY;
  final double phase;
  final double radius;

  const _NeuralNode({
    required this.anchor,
    required this.orbitX,
    required this.orbitY,
    required this.phase,
    required this.radius,
  });
}

class NeuralConnectionPainter extends CustomPainter {
  final Animation<double> animation;
  final double progress;
  final bool isImploding;

  NeuralConnectionPainter({
    required this.animation,
    required this.progress,
    required this.isImploding,
  }) : super(repaint: animation);

  static final List<_NeuralNode> _nodes = [
    const _NeuralNode(anchor: Offset(0.18, 0.24), orbitX: 0.015, orbitY: 0.022, phase: 0.2, radius: 3.6),
    const _NeuralNode(anchor: Offset(0.34, 0.18), orbitX: 0.02, orbitY: 0.018, phase: 1.0, radius: 3.1),
    const _NeuralNode(anchor: Offset(0.52, 0.22), orbitX: 0.016, orbitY: 0.024, phase: 1.7, radius: 2.8),
    const _NeuralNode(anchor: Offset(0.74, 0.19), orbitX: 0.024, orbitY: 0.016, phase: 2.2, radius: 3.2),
    const _NeuralNode(anchor: Offset(0.84, 0.34), orbitX: 0.018, orbitY: 0.023, phase: 2.8, radius: 2.9),
    const _NeuralNode(anchor: Offset(0.68, 0.46), orbitX: 0.025, orbitY: 0.019, phase: 3.3, radius: 3.5),
    const _NeuralNode(anchor: Offset(0.54, 0.58), orbitX: 0.014, orbitY: 0.015, phase: 4.1, radius: 3.4),
    const _NeuralNode(anchor: Offset(0.30, 0.52), orbitX: 0.021, orbitY: 0.022, phase: 4.7, radius: 3.0),
    const _NeuralNode(anchor: Offset(0.16, 0.62), orbitX: 0.02, orbitY: 0.018, phase: 5.0, radius: 2.7),
    const _NeuralNode(anchor: Offset(0.38, 0.78), orbitX: 0.022, orbitY: 0.02, phase: 5.6, radius: 3.2),
    const _NeuralNode(anchor: Offset(0.62, 0.76), orbitX: 0.019, orbitY: 0.021, phase: 6.0, radius: 3.3),
    const _NeuralNode(anchor: Offset(0.82, 0.66), orbitX: 0.02, orbitY: 0.018, phase: 6.5, radius: 2.9),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final time = animation.value * math.pi * 2;

    final points = _nodes.map((node) {
      final base = Offset(size.width * node.anchor.dx, size.height * node.anchor.dy);
      final orbit = Offset(
        math.sin(time + node.phase) * size.width * node.orbitX,
        math.cos((time * 0.9) + node.phase) * size.height * node.orbitY,
      );

      Offset point = base + orbit;
      if (isImploding) {
        point = Offset.lerp(point, center, Curves.easeInCubic.transform(progress))!;
      }
      return point;
    }).toList();

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..color = const Color(0xFFB9BEC7);
    final nodeGlowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final visibleConnections = 0.25 + (0.75 * progress);

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final distance = (points[i] - points[j]).distance;
        if (distance > size.width * 0.34) {
          continue;
        }

        final pairFactor = ((i + j) % 10) / 10;
        if (pairFactor > visibleConnections) {
          continue;
        }

        final opacity = (1 - (distance / (size.width * 0.34))).clamp(0.0, 1.0);
        final lineOpacity = opacity * (isImploding ? (1 - progress).clamp(0.0, 1.0) : 1.0);

        glowPaint.color = const Color(0xFF00E5FF).withValues(alpha: 0.12 + (lineOpacity * 0.14));
        linePaint.color = const Color(0xFF00E5FF).withValues(alpha: 0.28 + (lineOpacity * 0.52));

        canvas.drawLine(points[i], points[j], glowPaint);
        canvas.drawLine(points[i], points[j], linePaint);
      }
    }

    for (int i = 0; i < points.length; i++) {
      final radius = isImploding ? _nodes[i].radius * (1 - progress).clamp(0.2, 1.0) : _nodes[i].radius;
      canvas.drawCircle(points[i], radius * 2.4, nodeGlowPaint);
      canvas.drawCircle(points[i], radius, nodePaint);
    }

    if (isImploding) {
      final dotRadius = 5 + (12 * (1 - progress).clamp(0.0, 1.0));
      final implodePaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, dotRadius, implodePaint);
      canvas.drawCircle(center, 3.2, Paint()..color = const Color(0xFF00E5FF));
    }
  }

  @override
  bool shouldRepaint(covariant NeuralConnectionPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isImploding != isImploding ||
        oldDelegate.animation.value != animation.value;
  }
}
