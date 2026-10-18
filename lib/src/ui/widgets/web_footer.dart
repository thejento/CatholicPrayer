import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_info.dart';
import '../../data/link_opener.dart';
import '../../l10n/generated/app_localizations.dart';

/// Bottom of the home screen on the web: version, the Android app and where
/// to report a problem (DESIGN §3.14).
class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Future<void> open(Uri url) async {
      final messenger = ScaffoldMessenger.of(context);
      if (!await context.read<LinkOpener>()(url)) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.linkOpenFailed)));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          appBuild.isEmpty
              ? l10n.appVersion(appVersion)
              : '${l10n.appVersion(appVersion)} · $appBuild',
          key: const Key('app-version'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton.icon(
              key: const Key('play-store-link'),
              icon: const Icon(Icons.android),
              label: Text(l10n.playStoreLink),
              onPressed: () => open(playStoreUrl),
            ),
            TextButton.icon(
              key: const Key('issues-link'),
              icon: const Icon(Icons.bug_report_outlined),
              label: Text(l10n.reportIssueLink),
              onPressed: () => open(issuesUrl),
            ),
          ],
        ),
      ],
    );
  }
}
