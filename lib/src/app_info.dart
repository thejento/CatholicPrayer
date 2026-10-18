/// Version and project links shown in the web app's footer.
library;

/// Release builds pass the tag (`--dart-define=APP_VERSION=1.2.0`); otherwise
/// the pubspec version, which a test keeps in step.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

/// Short commit of a web deploy (`--dart-define=APP_BUILD=…`); empty locally.
const appBuild = String.fromEnvironment('APP_BUILD');

/// The Play Store page; live once the app is published there (O-10).
final playStoreUrl = Uri.parse(
  'https://play.google.com/store/apps/details?id=com.catholicrosarycompanion.crc',
);

final issuesUrl = Uri.parse('https://github.com/thejento/CatholicPrayer/issues');
