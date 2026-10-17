import 'dart:convert';
import 'dart:io';

import 'package:crc/src/audio/audio_catalog.dart';
import 'package:crc/src/audio/clips.dart';
import 'package:crc/src/l10n/generated/app_localizations.dart';
import 'package:crc/src/ui/step_text.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// Fails when a recording is missing or no longer matches its text, so the
/// voice can never drift from the words on screen (DESIGN §3.7).
/// Fix: run tool/tts/render.py, or push and let render-audio.yml do it.
void main() {
  final content = loadRealContent();
  final voices =
      (jsonDecode(File('tool/tts/voices.json').readAsStringSync()) as Map<String, dynamic>)
        ..removeWhere((k, _) => k.startsWith('_'));
  final manifest =
      jsonDecode(File(AudioCatalog.manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final languages = manifest['languages'] as Map<String, dynamic>;

  for (final MapEntry(key: lang, value: voice) in voices.entries) {
    group('voice [$lang]', () {
      final texts = speakableTexts(
        content,
        lang,
        (g) => guidanceText(lookupAppLocalizations(Locale(lang)), g),
      );
      final entry = languages[lang] as Map<String, dynamic>?;

      test('was rendered with the configured voice', () {
        expect(entry, isNotNull, reason: 'no recordings for $lang');
        expect(entry!['voice'], (voice as Map<String, dynamic>)['id']);
      });

      test('has an up-to-date recording for every spoken text', () {
        final clips = entry!['clips'] as Map<String, dynamic>;
        expect(clips.keys.toSet(), texts.keys.toSet());
        for (final MapEntry(key: id, value: text) in texts.entries) {
          final clip = clips[id] as Map<String, dynamic>;
          expect(
            clip['sha256'],
            sha256.convert(utf8.encode(text)).toString(),
            reason: '$id is stale',
          );
          expect(
            File('assets/audio/$lang/${clip['file']}').existsSync(),
            isTrue,
            reason: '$id file',
          );
        }
      });
    });
  }

  test('every language with content has a voice', () {
    expect(voices.keys.toSet(), languages.keys.toSet());
  });

  test('the catalog resolves asset paths from the manifest', () {
    final catalog = AudioCatalog.fromManifest(manifest);
    expect(catalog.asset('en', 'prayer_hail_mary'), 'assets/audio/en/prayer_hail_mary.mp3');
    expect(catalog.asset('en', 'nope'), isNull);
    expect(catalog.hasLanguage('xx'), isFalse);
  });
}
