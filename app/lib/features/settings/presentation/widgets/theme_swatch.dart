import 'package:flutter/material.dart';

/// A small three-wedge preview of a [ColorScheme] -- the Flutter take on the
/// MAUI reference's pie-wedge theme swatches (`Views/ThemePickerView.xaml`).
class ThemeSwatch extends StatelessWidget {
  final ColorScheme scheme;
  final bool selected;

  const ThemeSwatch({super.key, required this.scheme, required this.selected});

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _PieWedgePainter(
          primary: scheme.primary,
          secondary: scheme.secondary,
          tertiary: scheme.tertiary,
          border: Theme.of(context).colorScheme.surface,
        ),
        child: selected
            ? Center(
                child: Icon(
                  Icons.check,
                  color: scheme.onPrimary,
                  size: 22,
                  shadows: const [
                    Shadow(color: Colors.black45, blurRadius: 2),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

class _PieWedgePainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color border;

  const _PieWedgePainter({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.border,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    void drawWedge(Color color, double startDegrees, double sweepDegrees) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        rect,
        startDegrees * (3.1415926535 / 180),
        sweepDegrees * (3.1415926535 / 180),
        true,
        paint,
      );
    }

    // Three unequal wedges so all three tones stay legible at swatch size.
    drawWedge(primary, -90, 150);
    drawWedge(secondary, 60, 105);
    drawWedge(tertiary, 165, 105);

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _PieWedgePainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.tertiary != tertiary ||
        oldDelegate.border != border;
  }
}
