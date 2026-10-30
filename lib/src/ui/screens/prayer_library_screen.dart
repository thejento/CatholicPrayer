import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/content_repository.dart';
import '../../domain/rosary_sequence.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/prayer.dart';
import '../step_text.dart';
import 'prayer_detail_screen.dart';

/// The prayers of the Rosary, then other traditional prayers (DESIGN §3.12).
class PrayerLibraryScreen extends StatelessWidget {
  const PrayerLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prayers = context.read<ContentRepository>().prayers;
    final rosaryIds = buildRosarySequence().map((s) => s.prayerId).nonNulls.toSet();
    final chapletIds = buildDivineMercySequence()
        .map((s) => s.prayerId)
        .nonNulls
        .toSet()
        .difference(rosaryIds);
    final rosary = prayers.where((p) => rosaryIds.contains(p.id)).toList();
    final chaplet = prayers.where((p) => chapletIds.contains(p.id)).toList();
    final others = prayers
        .where((p) => !rosaryIds.contains(p.id) && !chapletIds.contains(p.id))
        .toList();
    final lang = contentLanguage(context);
    final headerStyle = Theme.of(context).textTheme.titleSmall
        ?.copyWith(color: Theme.of(context).colorScheme.primary);

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(header: true, child: Text(text, style: headerStyle)),
    );
    Widget tile(Prayer p, {bool first = false}) => ListTile(
      autofocus: first,
      title: Text(p.titleFor(lang)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => PrayerDetailScreen(prayer: p))),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.prayerLibrary)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            children: [
              header(l10n.rosaryPrayersSection),
              for (final (i, p) in rosary.indexed) tile(p, first: i == 0),
              header(l10n.divineMercyChaplet),
              for (final p in chaplet) tile(p),
              if (others.isNotEmpty) ...[
                header(l10n.otherPrayersSection),
                for (final p in others) tile(p),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
