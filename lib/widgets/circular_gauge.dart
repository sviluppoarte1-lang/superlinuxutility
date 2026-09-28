import 'dart:math';
import 'package:flutter/material.dart';

/// A circular donut gauge that displays a percentage value.
///
/// [value] is 0..100, [label] is shown below the percentage,
/// [color] is the arc color, [size] is the total widget size.
class CircularGauge extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  final double size;
  final String? subtitle;

  const CircularGauge({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.size = 140,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 100.0);
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _GaugePainter(
                value: clamped,
                color: color,
                trackColor: theme.colorScheme.surfaceContainerHighest,
                textColor: theme.colorScheme.onSurface,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${clamped.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: size * 0.22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: size * 0.085,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color trackColor;
  final Color textColor;

  _GaugePainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.13;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, trackPaint);

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * (value / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -pi / 2, // start from top
      sweepAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
