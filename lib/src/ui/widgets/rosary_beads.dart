import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/rosary_sequence.dart';

/// Computes where each bead sits inside a box of [size].
///
/// The loop (medal + 54 beads) is laid out on a circle with the medal at the
/// bottom; the pendant hangs straight down from the medal to the crucifix.
List<Offset> beadPositions(Size size) {
  final w = size.width;
  final h = size.height;
  // The pendant takes 6 spacings below the loop.
  final radius = math.min(w * 0.45, h / 3.3);
  final spacing = radius * 0.2;
  final center = Offset(w / 2, radius * 1.05);
  final medal = center + Offset(0, radius);

  const loopLength = beadCount - medalBead; // medal + 54 beads = 55
  final positions = List<Offset>.filled(beadCount, Offset.zero);
  for (var i = medalBead; i < beadCount; i++) {
    // Start at the bottom (pi/2) and go clockwise on screen.
    final angle = math.pi / 2 + (i - medalBead) / loopLength * 2 * math.pi;
    positions[i] = center + Offset(math.cos(angle), math.sin(angle)) * radius;
  }
  // Pendant: bead 5 just below the medal, down to the crucifix (0).
  for (var i = 0; i < medalBead; i++) {
    positions[i] = medal + Offset(0, (medalBead - i) * spacing);
  }
  return positions;
}

/// Draws the rosary and highlights the [current] bead. Beads in [visited]
/// are drawn as already prayed.
class RosaryBeads extends StatelessWidget {
  const RosaryBeads({
    super.key,
    required this.current,
    required this.visited,
    this.onCurrentBeadTap,
    this.semanticLabel,
  });

  final int current;
  final Set<int> visited;
  final VoidCallback? onCurrentBeadTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      button: onCurrentBeadTap != null,
      onTap: onCurrentBeadTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final positions = beadPositions(size);
              final target = positions[current];
              final tolerance = math.max(28.0, size.shortestSide * 0.08);
              if ((details.localPosition - target).distance <= tolerance) {
                onCurrentBeadTap?.call();
              }
            },
            child: TweenAnimationBuilder<double>(
              key: ValueKey(current),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 450),
              builder: (context, glow, _) => CustomPaint(
                size: size,
                painter: RosaryPainter(
                  current: current,
                  visited: visited,
                  glow: glow,
                  threadColor: scheme.outline,
                  beadColor: scheme.primary,
                  pendingColor: scheme.surfaceContainerHighest,
                  highlightColor: scheme.secondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RosaryPainter extends CustomPainter {
  RosaryPainter({
    required this.current,
    required this.visited,
    required this.glow,
    required this.threadColor,
    required this.beadColor,
    required this.pendingColor,
    required this.highlightColor,
  });

  final int current;
  final Set<int> visited;
  final double glow;
  final Color threadColor;
  final Color beadColor;
  final Color pendingColor;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final pos = beadPositions(size);
    final unit = (pos[1] - pos[0]).distance; // pendant spacing
    final thread = Paint()
      ..color = threadColor
      ..strokeWidth = math.max(1, unit * 0.06)
      ..style = PaintingStyle.stroke;

    // Thread: pendant, then the loop back to the medal.
    final path = Path()..moveTo(pos[0].dx, pos[0].dy);
    for (var i = 1; i < beadCount; i++) {
      path.lineTo(pos[i].dx, pos[i].dy);
    }
    path.lineTo(pos[medalBead].dx, pos[medalBead].dy);
    canvas.drawPath(path, thread);

    for (var i = 0; i < beadCount; i++) {
      final kind = beadKindAt(i);
      final r = switch (kind) {
        BeadKind.small => unit * 0.28,
        BeadKind.large => unit * 0.42,
        BeadKind.medal => unit * 0.5,
        BeadKind.crucifix => unit * 0.6,
      };
      final done = visited.contains(i) || i == current;
      final fill = Paint()..color = done ? beadColor : pendingColor;
      final outline = Paint()
        ..color = beadColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, unit * 0.05);

      if (i == current) {
        final halo = Paint()
          ..color = highlightColor.withValues(alpha: 0.35 + 0.35 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.3);
        canvas.drawCircle(pos[i], r * (1.6 + 0.6 * glow), halo);
      }

      switch (kind) {
        case BeadKind.crucifix:
          final bar = r * 0.35;
          final cross = Path()
            ..addRect(
              Rect.fromCenter(center: pos[i] + Offset(0, r * 0.2), width: bar, height: r * 2.4),
            )
            ..addRect(
              Rect.fromCenter(center: pos[i] - Offset(0, r * 0.35), width: r * 1.5, height: bar),
            );
          canvas.drawPath(cross, fill);
          canvas.drawPath(cross, outline);
        case BeadKind.medal:
          final medal = Rect.fromCenter(center: pos[i], width: r * 1.6, height: r * 2.0);
          canvas.drawOval(medal, fill);
          canvas.drawOval(medal, outline);
        case BeadKind.large || BeadKind.small:
          canvas.drawCircle(pos[i], r, fill);
          canvas.drawCircle(pos[i], r, outline);
      }

      if (i == current) {
        canvas.drawCircle(
          pos[i],
          r * 1.35,
          Paint()
            ..color = highlightColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(2, unit * 0.12),
        );
      }
    }
  }

  @override
  bool shouldRepaint(RosaryPainter old) =>
      old.current != current ||
      old.visited.length != visited.length ||
      old.glow != glow ||
      old.beadColor != beadColor ||
      old.highlightColor != highlightColor;
}
