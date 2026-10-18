import 'package:url_launcher/url_launcher.dart';

/// Opens a web page outside the app; tests pass a fake.
typedef LinkOpener = Future<bool> Function(Uri uri);

/// Opens [uri] in the browser. The app itself never goes online (DESIGN §9).
Future<bool> openInBrowser(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
