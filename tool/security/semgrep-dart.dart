// Test cases for semgrep-dart.yml: `semgrep --test tool/security/`.
// Not app code: excluded from `flutter analyze` (analysis_options.yaml).
// ruleid: no-network-client
import 'package:http/http.dart' as http;
// ok: no-network-client
import 'package:url_launcher/url_launcher.dart';

Future<void> examples(String fromData, AudioPlayer player) async {
  // ruleid: no-network-client
  final client = HttpClient();
  // ruleid: no-network-client
  await player.setUrl('https://example.org/a.mp3');

  // ruleid: launch-url-outside-link-opener
  await launchUrl(Uri.parse('https://example.org/'), mode: LaunchMode.externalApplication);
  // ruleid: launch-url-in-app, launch-url-outside-link-opener
  await launchUrl(Uri.parse('https://example.org/'), mode: LaunchMode.inAppWebView);

  // ruleid: cleartext-url, link-from-non-constant
  Uri.parse('http://example.org/');

  // ruleid: link-from-non-constant
  Uri.parse(fromData);
  // ruleid: link-from-non-constant
  Uri.parse('https://$fromData/page');
  // ok: link-from-non-constant
  Uri.parse('https://www.vaticannews.va/en/saints/$fromData.html');
  // ok: link-from-non-constant
  Uri.parse('https://github.com/thejento/CatholicPrayer/issues');
}
