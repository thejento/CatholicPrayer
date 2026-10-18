import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/link_opener.dart';
import '../l10n/generated/app_localizations.dart';

/// Opens [url] in the browser, or says so if it could not.
Future<void> openLink(BuildContext context, Uri url) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = AppLocalizations.of(context).linkOpenFailed;
  if (!await context.read<LinkOpener>()(url)) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
}
