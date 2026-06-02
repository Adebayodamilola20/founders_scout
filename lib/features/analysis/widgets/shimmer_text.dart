import 'package:flutter/material.dart';

class ShimmerText extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerText({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.duration = const Duration(milliseconds: 2500),
    this.baseColor = const Color(0xFF2D2D2D),
    this.highlightColor = const Color(0xFFF3F4F6),
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
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
        final value = _controller.value;
        final start = -0.5 + value;
        final end = start + 0.5;

        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(start, 0),
              end: Alignment(end, 0),
              colors: [
                widget.baseColor,
                widget.baseColor,
                widget.baseColor.withValues(alpha: 0.7),
                widget.highlightColor,
                widget.baseColor.withValues(alpha: 0.78),
                widget.baseColor,
                widget.baseColor,
              ],
              stops: const [
                0.0,
                0.35,
                0.45,
                0.5,
                0.55,
                0.65,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.baseColor,
              fontSize: widget.fontSize,
              fontWeight: widget.fontWeight,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
