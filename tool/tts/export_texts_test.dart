// Exports every spoken text to build/tts/texts.json for tool/tts/render.py.
//
//   flutter test tool/tts/export_texts_test.dart
//
// The texts come from the app's own code (speakableTexts), so the render
// tool and the freshness test can never disagree on what is spoken.
import 'dart:convert';
import 'dart:io';

import 'package:crc/src/audio/clips.dart';
import 'package:crc/src/data/content_repository.dart';
import 'package:crc/src/l10n/generated/app_localizations.dart';
import 'package:crc/src/ui/step_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/test_app.dart';

void main() {
  test('export spoken texts', () {
    final content = loadRealContent();
    final texts = {
      for (final lang in contentLanguages)
        lang: speakableTexts(
          content,
          lang,
          (g) => guidanceText(lookupAppLocalizations(Locale(lang)), g),
        ),
    };
    File('build/tts/texts.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(texts));
  });
}
