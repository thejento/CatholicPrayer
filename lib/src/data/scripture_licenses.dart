import 'package:flutter/foundation.dart';

/// Credits for the Bible translations, shown on the licence page (ADR-024).
/// The néo-Crampon Libre is CC BY-SA 4.0, which requires attribution.
void registerScriptureLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Scripture: Sainte Bible néo-Crampon Libre'],
      '''
French Bible passages: Sainte Bible néo-Crampon Libre, a modernisation of the Catholic
Crampon translation. Copyright © 2022 Fraternité de Tibériade. Licensed under the Creative
Commons Attribution-ShareAlike 4.0 licence (https://creativecommons.org/licenses/by-sa/4.0/).
Unmodified excerpts, from eBible.org (https://ebible.org/Scriptures/details.php?id=francl),
except Luke 1:45, which is cut short there and is completed from the Crampon 1923 (public domain).''',
    );
    yield const LicenseEntryWithLineBreaks(
      ['Scripture: Douay-Rheims Bible'],
      '''
English Bible passages: Douay-Rheims Bible, 1899 American Edition. Public domain.
Text from eBible.org (https://ebible.org/Scriptures/details.php?id=engDRA).''',
    );
    yield const LicenseEntryWithLineBreaks(
      ['Scripture: Torres Amat'],
      '''
Spanish Bible passages: La Sagrada Biblia, translated by Félix Torres Amat (1836 edition).
Public domain. Text from the Spanish Wikisource transcription
(https://es.wikisource.org/wiki/La_Sagrada_Biblia_(XIII)), with modernized spelling.''',
    );
  });
}
