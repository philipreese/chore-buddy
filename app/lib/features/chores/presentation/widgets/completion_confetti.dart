import 'dart:math';

import 'package:flutter/material.dart';

/// Shows a short (~900ms), non-interactive confetti burst over [context]'s
/// nearest Overlay, sampled from the current dynamic color scheme. Skipped
/// entirely when the platform (or a test) has animations disabled -- see
/// `MediaQuery.disableAnimationsOf`. The overlay entry removes itself once
/// the burst finishes, so callers never have to track or dispose it.
void showCompletionConfetti(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) return;

  final overlayState = Overlay.maybeOf(context, rootOverlay: true);
  if (overlayState == null) return;

  final colorScheme = Theme.of(context).colorScheme;
  final colors = [
    colorScheme.primary,
    colorScheme.tertiary,
    colorScheme.error,
    // Fixed accent: no dynamic-scheme role reliably reads as "confetti
    // yellow", and a burst sampled entirely from primary/tertiary/error
    // reads as muted on many wallpaper-derived palettes.
    const Color(0xFFFFD54F),
  ];

  var removed = false;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => CompletionConfettiOverlay(
      colors: colors,
      onFinished: () {
        if (!removed) {
          removed = true;
          entry.remove();
        }
      },
    ),
  );
  overlayState.insert(entry);
}

class _Particle {
  final double startXFraction;
  final double fallDistanceFraction;
  final double horizontalDriftFraction;
  final double rotationRadians;
  final double size;
  final double delay;
  final Color color;

  const _Particle({
    required this.startXFraction,
    required this.fallDistanceFraction,
    required this.horizontalDriftFraction,
    required this.rotationRadians,
    required this.size,
    required this.delay,
    required this.color,
  });
}

List<_Particle> _generateParticles(List<Color> colors) {
  final random = Random();
  final count = 20 + random.nextInt(21); // 20..40 inclusive
  return List.generate(count, (_) {
    return _Particle(
      startXFraction: random.nextDouble(),
      fallDistanceFraction: 0.5 + random.nextDouble() * 0.5,
      horizontalDriftFraction: (random.nextDouble() - 0.5) * 0.3,
      rotationRadians: (random.nextDouble() - 0.5) * 8,
      size: 6 + random.nextDouble() * 6,
      // Staggered start so the burst reads as scattering outward rather
      // than every particle falling in lockstep.
      delay: random.nextDouble() * 0.2,
      color: colors[random.nextInt(colors.length)],
    );
  });
}

/// Non-interactive (`IgnorePointer`) confetti burst painted with a plain
/// `CustomPainter` + `AnimationController` -- see spec 19's changes.md for
/// why this was chosen over the `confetti` pub package.
class CompletionConfettiOverlay extends StatefulWidget {
  final List<Color> colors;
  final VoidCallback onFinished;

  const CompletionConfettiOverlay({
    super.key,
    required this.colors,
    required this.onFinished,
  });

  @override
  State<CompletionConfettiOverlay> createState() =>
      _CompletionConfettiOverlayState();
}

class _CompletionConfettiOverlayState extends State<CompletionConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _generateParticles(widget.colors);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _controller.addStatusListener(_handleStatus);
    _controller.forward();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final particle in particles) {
      final localT =
          ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final opacity = (1 - localT).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      final x = particle.startXFraction * size.width +
          particle.horizontalDriftFraction * size.width * localT;
      final y = size.height * 0.05 +
          particle.fallDistanceFraction * size.height * localT;

      paint.color = particle.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotationRadians * localT);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
