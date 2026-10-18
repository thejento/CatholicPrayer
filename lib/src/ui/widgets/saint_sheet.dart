import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/device_profile.dart';
import '../../data/link_opener.dart';
import '../../data/saint_links.dart';
import '../../data/saints_repository.dart';
import '../../domain/sanctoral.dart';
import '../../l10n/generated/app_localizations.dart';
import '../liturgy_text.dart';
import '../step_text.dart';

/// The day's celebrations, what their rank means, and a link to the saint of
/// the day on Vatican News (DESIGN §3.11).
Future<void> showSaintSheet(BuildContext context, DateTime date, List<Celebration> celebrations) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _SaintSheet(date: date, celebrations: celebrations),
  );
}

class _SaintSheet extends StatelessWidget {
  const _SaintSheet({required this.date, required this.celebrations});

  final DateTime date;
  final List<Celebration> celebrations;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = contentLanguage(context);
    final saints = context.read<SaintsRepository>();
    final url = saintOfTheDayUrl(date, lang);
    final tv = context.read<DeviceProfile>().isTelevision;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.saintOfTheDay, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 16),
            for (final c in celebrations) ...[
              Text(saints.name(c.id, lang), style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${rankName(l10n, c.rank)}: ${rankAbout(l10n, c.rank)}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            // TVs rarely have a browser: show the address to open elsewhere.
            if (tv) ...[
              Text(l10n.vaticanNewsOnTv, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 4),
              SelectableText(
                url.toString(),
                key: const Key('saint-url'),
                style: theme.textTheme.titleMedium,
              ),
            ] else
              FilledButton.icon(
                key: const Key('saint-link'),
                autofocus: true,
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.readOnVaticanNews),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (!await context.read<LinkOpener>()(url)) {
                    messenger.showSnackBar(SnackBar(content: Text(l10n.linkOpenFailed)));
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
