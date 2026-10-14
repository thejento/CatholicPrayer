// Renders the app icon, TV banner and store graphics from code.
//
//   flutter test tool/render_icons_test.dart
//
// Lives outside test/ so it does not run in CI. The banner text uses DejaVu
// Serif when it is installed (Linux); without it the banner has no text.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const maroon = Color(0xFF6B1E23);
const maroonDark = Color(0xFF4A1418);
const gold = Color(0xFFE2BC4A);
const cream = Color(0xFFFFF6E0);
const fontPath = '/usr/share/fonts/truetype/DejaVuSerif.ttf';

/// Draws the rosary emblem inside a [box]: a ring of beads, a short pendant
/// and a cross.
void drawEmblem(Canvas canvas, Rect box) {
  final s = box.shortestSide;
  final cx = box.center.dx;
  final top = box.center.dy - s * 0.5;
  final paint = Paint()..color = gold;
  final line = Paint()
    ..color = gold
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.012;

  final ringCenter = Offset(cx, top + s * 0.36);
  final radius = s * 0.27;
  canvas.drawCircle(ringCenter, radius, line);
  const beads = 20;
  for (var i = 0; i < beads; i++) {
    final a = math.pi / 2 + i / beads * 2 * math.pi;
    final p = ringCenter + Offset(math.cos(a), math.sin(a)) * radius;
    final large = i == 0 || i == beads ~/ 2;
    canvas.drawCircle(p, s * (large ? 0.042 : 0.03), paint);
  }

  final medal = ringCenter + Offset(0, radius);
  final crossTop = medal + Offset(0, s * 0.22);
  canvas.drawLine(medal, crossTop, line);
  canvas.drawCircle(medal + Offset(0, s * 0.1), s * 0.036, paint);

  final bar = s * 0.05;
  final cross = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bar / 2, crossTop.dy, bar, s * 0.26),
        Radius.circular(bar * 0.3),
      ),
    )
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, crossTop.dy + s * 0.075), width: s * 0.17, height: bar),
        Radius.circular(bar * 0.3),
      ),
    );
  canvas.drawPath(cross, paint);
}

void drawBackground(Canvas canvas, Rect rect, {double cornerRadius = 0}) {
  final gradient = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [maroon, maroonDark],
    ).createShader(rect);
  canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)), gradient);
}

/// Lays out [text] at the largest size up to [maxSize] that fits [maxWidth]
/// without wrapping words.
TextPainter fitText(String text, double maxSize, double maxWidth) {
  for (var size = maxSize; ; size *= 0.95) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: 'DejaVuSerif', fontSize: size, color: cream, height: 1.15),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    if (painter.width <= maxWidth || size < 4) return painter;
  }
}

Future<void> render(String path, int w, int h, void Function(Canvas, Size) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder), Size(w.toDouble(), h.toDouble()));
  final image = await recorder.endRecording().toImage(w, h);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// Standard icon: rounded square, emblem with some padding.
void icon(Canvas c, Size size) {
  final rect = Offset.zero & size;
  drawBackground(c, rect, cornerRadius: size.width * 0.22);
  drawEmblem(c, rect.deflate(size.width * 0.1));
}

/// Maskable icon: full bleed, emblem inside the 80 % safe zone.
void maskable(Canvas c, Size size) {
  final rect = Offset.zero & size;
  drawBackground(c, rect);
  drawEmblem(c, rect.deflate(size.width * 0.2));
}

void Function(Canvas, Size) wide({required bool hasFont, required String title, String? subtitle}) {
  return (c, size) {
    final rect = Offset.zero & size;
    drawBackground(c, rect);
    final h = size.height;
    drawEmblem(c, Rect.fromLTWH(h * 0.1, h * 0.1, h * 0.8, h * 0.8));
    if (!hasFont) return;
    final x = h * 0.98;
    final width = size.width - x - h * 0.08;
    final titlePainter = fitText(title, h * 0.2, width);
    final subtitlePainter = subtitle == null ? null : fitText(subtitle, h * 0.075, width);
    final gap = subtitlePainter == null ? 0.0 : h * 0.05;
    final total = titlePainter.height + gap + (subtitlePainter?.height ?? 0);
    var y = (h - total) / 2;
    titlePainter.paint(c, Offset(x, y));
    y += titlePainter.height + gap;
    subtitlePainter?.paint(c, Offset(x, y));
  };
}

void main() {
  testWidgets('render icons', (tester) async {
    await tester.runAsync(() async {
      final hasFont = File(fontPath).existsSync();
      if (hasFont) {
        final loader = FontLoader('DejaVuSerif')
          ..addFont(Future.value(ByteData.sublistView(File(fontPath).readAsBytesSync())));
        await loader.load();
      }

      const mipmaps = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
      for (final MapEntry(key: density, value: px) in mipmaps.entries) {
        await render('android/app/src/main/res/mipmap-$density/ic_launcher.png', px, px, icon);
      }
      await render('web/favicon.png', 32, 32, icon);
      await render('web/icons/Icon-192.png', 192, 192, icon);
      await render('web/icons/Icon-512.png', 512, 512, icon);
      await render('web/icons/Icon-maskable-192.png', 192, 192, maskable);
      await render('web/icons/Icon-maskable-512.png', 512, 512, maskable);

      // Android TV banner: 320x180 dp at xhdpi.
      await render(
        'android/app/src/main/res/drawable-xhdpi/tv_banner.png',
        640,
        360,
        wide(hasFont: hasFont, title: 'Rosary\nCompanion'),
      );
      // Google Play listing assets (backlog O-10).
      await render('store/icon-512.png', 512, 512, maskable);
      await render(
        'store/feature-graphic-1024x500.png',
        1024,
        500,
        wide(
          hasFont: hasFont,
          title: 'Rosary\nCompanion',
          subtitle: 'Learn to pray the Rosary,\none bead at a time.',
        ),
      );
    });
  });
}
