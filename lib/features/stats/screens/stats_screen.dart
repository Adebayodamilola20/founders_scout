import 'package:flutter/material.dart';

import '../../leads/models/lead_outreach_state.dart';
import '../../leads/services/outreach_tracker_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    final states = OutreachTrackerService.instance.states.value;
    final allStates = states.values.toList();

    final totalLeads = allStates.length;
    final contacted = allStates.where((s) => s.stage == LeadPipelineStage.contacted).length;
    final replied = allStates.where((s) => s.replied == true).length;
    final closed = allStates.where((s) => s.stage == LeadPipelineStage.closed).length;
    final fresh = allStates.where((s) => s.stage == LeadPipelineStage.fresh).length;

    final contactRate = totalLeads > 0 ? (contacted / totalLeads * 100).toStringAsFixed(0) : '0';
    final replyRate = contacted > 0 ? (replied / contacted * 100).toStringAsFixed(0) : '0';
    final closeRate = contacted > 0 ? (closed / contacted * 100).toStringAsFixed(0) : '0';

    final channels = <String, int>{};
    for (final state in allStates) {
      final channel = state.channel;
      if (channel != null && channel.isNotEmpty) {
        channels[channel] = (channels[channel] ?? 0) + 1;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final circleSize = (screenWidth - 36 - 48) / 2.2; // 2 per row, medium size

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Stats',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your outreach performance at a glance',
                style: TextStyle(
                  color: Color(0xFF6F6F6F),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Wrap(
                  spacing: 32,
                  runSpacing: 32,
                  alignment: WrapAlignment.center,
                  children: [
                    _StatCircle(
                      label: 'Leads',
                      value: totalLeads,
                      color: const Color(0xFF6366F1),
                      bg: const Color(0xFFEEF2FF),
                      size: circleSize,
                    ),
                    _StatCircle(
                      label: 'Contacted',
                      value: contacted,
                      color: const Color(0xFF3B82F6),
                      bg: const Color(0xFFEFF6FF),
                      size: circleSize,
                    ),
                    _StatCircle(
                      label: 'Replied',
                      value: replied,
                      color: const Color(0xFF22C55E),
                      bg: const Color(0xFFECFDF5),
                      size: circleSize,
                    ),
                    _StatCircle(
                      label: 'Closed',
                      value: closed,
                      color: const Color(0xFFA855F7),
                      bg: const Color(0xFFF5F3FF),
                      size: circleSize,
                    ),
                    _StatCircle(
                      label: 'Fresh',
                      value: fresh,
                      color: const Color(0xFFF59E0B),
                      bg: const Color(0xFFFEF3C7),
                      size: circleSize,
                    ),
                    _StatCircle(
                      label: 'Contact Rate',
                      value: int.parse(contactRate),
                      suffix: '%',
                      color: const Color(0xFFEC4899),
                      bg: const Color(0xFFFDF2F8),
                      size: circleSize,
                    ),
                    _StatCircle(
                      label: 'Reply Rate',
                      value: int.parse(replyRate),
                      suffix: '%',
                      color: const Color(0xFF14B8A6),
                      bg: const Color(0xFFF0FDFA),
                      size: circleSize,
                    ),
                    _StatCircle(
                      label: 'Close Rate',
                      value: int.parse(closeRate),
                      suffix: '%',
                      color: const Color(0xFFF97316),
                      bg: const Color(0xFFFFF7ED),
                      size: circleSize,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Conversion rates',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ConversionRow(
                      label: 'Contact → Reply',
                      value: replyRate,
                      total: contacted,
                      color: const Color(0xFF22C55E),
                    ),
                    const SizedBox(height: 14),
                    _ConversionRow(
                      label: 'Contact → Closed',
                      value: closeRate,
                      total: contacted,
                      color: const Color(0xFFA855F7),
                    ),
                  ],
                ),
              ),
              if (channels.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text(
                  'Channels used',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: channels.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F3),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCircle extends StatelessWidget {
  final String label;
  final int value;
  final String suffix;
  final Color color;
  final Color bg;
  final double size;

  const _StatCircle({
    required this.label,
    required this.value,
    this.suffix = '',
    required this.color,
    required this.bg,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(
            begin: 0,
            end: size,
          ),
          builder: (context, animatedSize, child) {
            return SizedBox(
              width: animatedSize,
              height: animatedSize,
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: TweenAnimationBuilder<int>(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                tween: IntTween(begin: 0, end: value),
                builder: (context, animatedValue, _) {
                  return Text(
                    '$animatedValue$suffix',
                    style: TextStyle(
                      color: color,
                      fontSize: size * 0.30,
                      fontWeight: FontWeight.w900,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: size,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6F6F6F),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConversionRow extends StatelessWidget {
  final String label;
  final String value;
  final int total;
  final Color color;

  const _ConversionRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6F6F6F),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '$value%',
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'from $total',
                    style: const TextStyle(
                      color: Color(0xFF8C8C8C),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(56, 56),
                painter: _CirclePainter(
                  progress: double.tryParse(value) ?? 0 / 100,
                  color: color,
                ),
              ),
              Center(
                child: Text(
                  '$value%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final Color color;

  _CirclePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = const Color(0xFFECECE8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      2 * 3.14159 * (progress / 100),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}
