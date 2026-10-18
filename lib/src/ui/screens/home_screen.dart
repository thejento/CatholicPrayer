import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/content_repository.dart';
import '../../data/saints_repository.dart';
import '../../domain/clock.dart';
import '../../domain/liturgical_calendar.dart';
import '../../domain/mysteries.dart';
import '../../domain/sanctoral.dart';
import '../../domain/rosary_sequence.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/saved_session_controller.dart';
import '../liturgy_text.dart';
import '../step_text.dart';
import 'mystery_picker_screen.dart';
import 'prayer_library_screen.dart';
import 'rosary_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = contentLanguage(context);
    final today = context.read<Clock>().now();
    final suggested = suggestedMysterySet(today);
    final liturgy = liturgicalDay(today);
    final note = sundayMysteriesNote(l10n, today, liturgy);
    final celebrations = celebrationsOn(today);
    final saints = context.read<SaintsRepository>();
    final content = context.read<ContentRepository>();
    final setTitle = content.mysterySetTitle(suggested).of(lang);
    final saved = context.watch<SavedSessionController>().saved;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.brightness_7_outlined, size: 72, color: theme.colorScheme.secondary),
                const SizedBox(height: 16),
                Text(
                  l10n.homeWelcome,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        key: const Key('liturgical-day'),
                        leading: _ColorDot(color: liturgicalColor(liturgy.color)),
                        title: Text(
                          liturgicalDayName(l10n, liturgy, lang),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (celebrations.isNotEmpty)
                        ListTile(
                          key: const Key('saint-of-the-day'),
                          leading: const Icon(Icons.auto_awesome_outlined),
                          title: Text(saints.name(celebrations.first.id, lang)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rankName(l10n, celebrations.first.rank)),
                              for (final other in celebrations.skip(1))
                                Text(l10n.orSaint(saints.name(other.id, lang))),
                            ],
                          ),
                        ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.today_outlined),
                        title: Text(l10n.suggestedToday),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(setTitle, style: theme.textTheme.titleMedium),
                            if (note != null) Text(note, key: const Key('sunday-note')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (saved != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: theme.colorScheme.secondaryContainer,
                    child: ListTile(
                      key: const Key('continue-rosary'),
                      leading: const Icon(Icons.history),
                      title: Text(l10n.continueRosary),
                      subtitle: Text(
                        '${content.mysterySetTitle(saved.mysterySet).of(lang)} · '
                        '${l10n.stepCounter(saved.index + 1, buildRosarySequence().length)}',
                      ),
                      trailing: const Icon(Icons.play_arrow_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              RosaryScreen(mysterySet: saved.mysterySet, startIndex: saved.index),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  autofocus: saved == null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.beginRosary),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MysteryPickerScreen(initial: suggested),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(l10n.prayerLibrary),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => const PrayerLibraryScreen())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The liturgical colour of the day; decorative, the name says it all.
class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      ),
    );
  }
}
