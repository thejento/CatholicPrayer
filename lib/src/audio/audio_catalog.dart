import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Index of the bundled voice recordings, read from
/// `assets/audio/manifest.json` (written by `tool/tts/render.py`).
class AudioCatalog {
  const AudioCatalog(this._clips);

  /// An empty catalog: no language has a voice.
  const AudioCatalog.empty() : _clips = const {};

  /// language → clip id → asset path.
  final Map<String, Map<String, String>> _clips;

  static const manifestPath = 'assets/audio/manifest.json';

  static Future<AudioCatalog> load(AssetBundle bundle) async {
    try {
      return AudioCatalog.fromManifest(
        jsonDecode(await bundle.loadString(manifestPath)) as Map<String, dynamic>,
      );
    } on FlutterError {
      return const AudioCatalog.empty(); // No audio bundled.
    }
  }

  factory AudioCatalog.fromManifest(Map<String, dynamic> manifest) {
    final languages = manifest['languages'] as Map<String, dynamic>? ?? const {};
    return AudioCatalog({
      for (final MapEntry(key: lang, value: entry) in languages.entries)
        lang: {
          for (final MapEntry(key: id, value: clip)
              in ((entry as Map<String, dynamic>)['clips'] as Map<String, dynamic>).entries)
            id: 'assets/audio/$lang/${(clip as Map<String, dynamic>)['file']}',
        },
    });
  }

  /// Whether [lang] has recordings; the voice is offered only then.
  bool hasLanguage(String lang) => _clips[lang]?.isNotEmpty ?? false;

  /// Asset path of [clipId] in [lang], or null when it was not recorded.
  String? asset(String lang, String clipId) => _clips[lang]?[clipId];
}
