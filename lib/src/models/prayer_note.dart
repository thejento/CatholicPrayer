import 'localized_text.dart';

/// Background on a prayer for the "About this prayer" page (DESIGN §3.17):
/// where it comes from, when it is prayed, and its Scripture roots if any.
/// These texts are the app's own, unlike the public-domain prayers.
class PrayerNote {
  const PrayerNote({required this.origin, required this.use, this.scripture});

  final LocalizedText origin;
  final LocalizedText use;

  /// Bible references, e.g. "Luke 1:28; Luke 1:42". Null when the prayer has
  /// no direct source in Scripture.
  final LocalizedText? scripture;
}
