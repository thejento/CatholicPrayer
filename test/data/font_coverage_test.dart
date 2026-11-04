import 'dart:io';

import 'package:crc/src/data/scripture_licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Characters the font maps, read from its `cmap` table (formats 4 and 12).
Set<int> _mappedCharacters(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final tables = data.getUint16(4);
  var cmap = -1;
  for (var i = 0; i < tables; i++) {
    final record = 12 + 16 * i;
    if (String.fromCharCodes(bytes.sublist(record, record + 4)) == 'cmap') {
      cmap = data.getUint32(record + 8);
    }
  }
  final mapped = <int>{};
  final subtables = data.getUint16(cmap + 2);
  for (var i = 0; i < subtables; i++) {
    final offset = cmap + data.getUint32(cmap + 4 + 8 * i + 4);
    switch (data.getUint16(offset)) {
      case 4:
        final segments = data.getUint16(offset + 6) ~/ 2;
        final ends = offset + 14;
        final starts = ends + 2 * segments + 2;
        final deltas = starts + 2 * segments;
        final ranges = deltas + 2 * segments;
        for (var s = 0; s < segments; s++) {
          final end = data.getUint16(ends + 2 * s);
          final start = data.getUint16(starts + 2 * s);
          final delta = data.getInt16(deltas + 2 * s);
          final rangeOffset = data.getUint16(ranges + 2 * s);
          for (var c = start; c <= end && c != 0xFFFF; c++) {
            final glyph = rangeOffset == 0
                ? (c + delta) & 0xFFFF
                : data.getUint16(ranges + 2 * s + rangeOffset + 2 * (c - start));
            if (glyph != 0) mapped.add(c);
          }
        }
      case 12:
        final groups = data.getUint32(offset + 12);
        for (var g = 0; g < groups; g++) {
          final group = offset + 16 + 12 * g;
          for (var c = data.getUint32(group); c <= data.getUint32(group + 4); c++) {
            mapped.add(c);
          }
        }
    }
  }
  return mapped;
}

/// The web app bundles Roboto so it never downloads a font (r-06, ADR-043).
/// A character missing from it would make the engine ask for a fallback font.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Roboto licence (SIL OFL) is on the credits page', () async {
    registerFontLicenses();
    final entries = await LicenseRegistry.licenses.toList();
    final roboto = entries.where((e) => e.packages.contains('Roboto font'));
    expect(roboto, hasLength(1));
    expect(
      roboto.single.paragraphs.map((p) => p.text).join(' '),
      contains('SIL Open Font License'),
    );
  });

  final texts = [
    ...Directory('assets/data').listSync(recursive: true).whereType<File>(),
    ...Directory('lib/src/l10n').listSync().whereType<File>().where((f) => f.path.endsWith('.arb')),
    ...Directory('lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('generated')),
  ].where((f) => f.path.endsWith('.json') || f.path.endsWith('.arb') || f.path.endsWith('.dart'));
  // Dart comments aren't shown, so only the code lines count.
  String shown(File file) => file.path.endsWith('.dart')
      ? file
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('//'))
            .map((line) => line.split(' // ').first)
            .join('\n')
      : file.readAsStringSync();
  final used = <int>{for (final file in texts) ...shown(file).runes};
  used.removeWhere((c) => c < 0x20);

  for (final face in Directory(
    'assets/fonts',
  ).listSync().whereType<File>().where((f) => f.path.endsWith('.ttf'))) {
    test('${face.uri.pathSegments.last} has every character of the texts', () {
      final mapped = _mappedCharacters(face.readAsBytesSync());
      final missing = used.difference(mapped).toList()..sort();
      expect(
        [for (final c in missing) 'U+${c.toRadixString(16).toUpperCase().padLeft(4, '0')}'],
        isEmpty,
        reason: 'add the range to UNICODES in tool/fonts/build_fonts.py',
      );
    });
  }
}
