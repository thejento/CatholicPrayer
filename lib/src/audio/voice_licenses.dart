import 'package:flutter/foundation.dart';

/// Credits for the voice recordings, shown on the licence page.
/// The SIWIS corpus is CC BY 4.0, which requires attribution.
void registerVoiceLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Voice: Kokoro-82M'],
      '''
Prayer recordings were generated with Kokoro-82M by hexgrad
(https://huggingface.co/hexgrad/Kokoro-82M), licensed under the Apache License 2.0.''',
    );
    yield const LicenseEntryWithLineBreaks(
      ['Voice: SIWIS French Speech Synthesis Database'],
      '''
The French Kokoro voice is derived from the SIWIS French Speech Synthesis Database
(Honnet, Lazaridis, Garner, Yamagishi), licensed under CC BY 4.0
(https://creativecommons.org/licenses/by/4.0/).''',
    );
    yield const LicenseEntryWithLineBreaks(
      ['Voice: Chatterbox'],
      '''
Some recordings may be generated with Chatterbox Multilingual by Resemble AI
(https://huggingface.co/ResembleAI/chatterbox), licensed under the MIT License.''',
    );
  });
}
