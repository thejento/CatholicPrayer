import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/content_repository.dart';
import '../../data/device_profile.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/prayer.dart';
import '../../routes.dart';
import '../step_text.dart';

/// Opens the background of [prayer]; nothing when it has none (DESIGN §3.17).
class AboutPrayerButton extends StatelessWidget {
  const AboutPrayerButton({super.key, required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    if (context.read<ContentRepository>().note(prayer.id) == null) return const SizedBox.shrink();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        key: const Key('about-prayer'),
        icon: const Icon(Icons.info_outline),
        label: Text(AppLocalizations.of(context).aboutPrayer),
        onPressed: () => context.push(Routes.aboutPrayer(prayer.id)),
      ),
    );
  }
}

/// Where a prayer comes from, when it is prayed, and its Scripture roots.
class PrayerAboutScreen extends StatelessWidget {
  const PrayerAboutScreen({super.key, required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final lang = contentLanguage(context);
    final note = context.read<ContentRepository>().note(prayer.id)!;
    // On TV the D-pad moves from section to section, scrolling as it goes.
    final tv = context.read<DeviceProfile>().isTelevision;
    final sections = [
      (l10n.noteOrigin, note.origin.of(lang)),
      (l10n.noteUse, note.use.of(lang)),
      if (note.scripture case final refs?) (l10n.noteScripture, refs.of(lang)),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutPrayer)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(prayer.titleFor(lang), style: theme.textTheme.headlineMedium),
              for (final (i, (heading, text)) in sections.indexed)
                Focus(
                  autofocus: tv && i == 0,
                  canRequestFocus: tv,
                  child: Builder(
                    builder: (context) => Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Focus.of(context).hasFocus
                            ? theme.colorScheme.secondaryContainer
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              heading,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            text,
                            key: Key('note-$i'),
                            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
