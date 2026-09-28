import 'package:flutter/material.dart';

class FeatureIconData {
  final IconData icon;
  final Color color;

  const FeatureIconData({required this.icon, required this.color});
}

class FeatureIcon extends StatelessWidget {
  final FeatureIconData data;
  final double size;

  const FeatureIcon({super.key, required this.data, this.size = 38});

  Color _lighten(Color c, double amount) {
    final r = (c.r + (1.0 - c.r) * amount).clamp(0.0, 1.0);
    final g = (c.g + (1.0 - c.g) * amount).clamp(0.0, 1.0);
    final b = (c.b + (1.0 - c.b) * amount).clamp(0.0, 1.0);
    return Color.from(alpha: c.a, red: r, green: g, blue: b);
  }

  Color _darken(Color c, double amount) {
    final r = (c.r * (1.0 - amount)).clamp(0.0, 1.0);
    final g = (c.g * (1.0 - amount)).clamp(0.0, 1.0);
    final b = (c.b * (1.0 - amount)).clamp(0.0, 1.0);
    return Color.from(alpha: c.a, red: r, green: g, blue: b);
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.55;
    final radius = size * 0.28;
    final c = data.color;
    final topLeft = _lighten(c, 0.55);
    final midLight = c;
    final midDark = _darken(c, 0.15);
    final bottomRight = _darken(c, 0.35);
    final shadowColor = _darken(c, 0.5);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topLeft, midLight, midDark, bottomRight],
          stops: const [0.0, 0.3, 0.65, 1.0],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.45),
            offset: const Offset(0, 3),
            blurRadius: 5,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: _lighten(c, 0.7).withValues(alpha: 0.3),
            offset: const Offset(-1, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Center(
              child: Icon(
                data.icon,
                size: iconSize,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    offset: const Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size * 0.35,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
