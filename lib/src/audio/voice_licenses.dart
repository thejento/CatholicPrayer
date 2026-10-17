import 'package:flutter/foundation.dart';

/// Credits for the voice recordings, shown on the licence page.
/// The Kyutai weights and the CML-TTS speaker are CC BY 4.0, which requires attribution.
void registerVoiceLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Voice: Kokoro-82M'],
      '''
Prayer recordings were generated with Kokoro-82M by hexgrad
(https://huggingface.co/hexgrad/Kokoro-82M), licensed under the Apache License 2.0.''',
    );
    yield const LicenseEntryWithLineBreaks(
      ['Voice: Kyutai TTS'],
      '''
French recordings were generated with Kyutai TTS 1.6B (en/fr) by Kyutai
(https://huggingface.co/kyutai/tts-1.6b-en_fr), model weights licensed under CC BY 4.0
(https://creativecommons.org/licenses/by/4.0/).''',
    );
    yield const LicenseEntryWithLineBreaks(
      ['Voice: CML-TTS French speaker'],
      '''
The French voice is conditioned on a recording of a LibriVox reader from the CML-TTS
dataset (Oliveira et al.), as distributed in kyutai/tts-voices
(cml-tts/fr/7400_2928_000100-0001_enhanced.wav), licensed under CC BY 4.0
(https://creativecommons.org/licenses/by/4.0/).''',
    );
  });
}
