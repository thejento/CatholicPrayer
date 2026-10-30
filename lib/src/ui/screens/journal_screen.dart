import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/content_repository.dart';
import '../../domain/clock.dart';
import '../../domain/rosary_sequence.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/journal_controller.dart';
import '../step_text.dart';

/// Asks for an intention; returns the text, or `null` when cancelled.
Future<String?> showIntentionDialog(BuildContext context, {String initial = ''}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _IntentionDialog(initial: initial),
    );

class _IntentionDialog extends StatefulWidget {
  const _IntentionDialog({required this.initial});

  final String initial;

  @override
  State<_IntentionDialog> createState() => _IntentionDialogState();
}

class _IntentionDialogState extends State<_IntentionDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.journalIntention),
      content: TextField(
        key: const Key('intention-field'),
        controller: _text,
        autofocus: true,
        maxLength: JournalController.maxIntention,
        maxLines: 3,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.journalIntentionHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          key: const Key('intention-save'),
          onPressed: () => Navigator.of(context).pop(_text.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// The private list of Rosaries prayed, newest first (DESIGN §3.20).
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final journal = context.watch<JournalController>();
    final content = context.read<ContentRepository>();
    final lang = contentLanguage(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = context.read<Clock>().now();
    final entries = journal.entries;

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Text(
          l10n.journalThisMonth(journal.countInMonth(now)),
          key: const Key('journal-count'),
          style: theme.textTheme.titleLarge,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(l10n.journalPrivacy, style: theme.textTheme.bodyMedium),
      ),
      if (entries.isEmpty)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.journalEmpty, key: const Key('journal-empty')),
        ),
    ];
    String? month;
    for (final (i, entry) in entries.indexed) {
      final heading = DateFormat.yMMMM(locale).format(entry.prayedAt);
      if (heading != month) {
        month = heading;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Semantics(
              header: true,
              child: Text(
                heading,
                style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
          ),
        );
      }
      final when =
          '${DateFormat.MMMMEEEEd(locale).format(entry.prayedAt)} · '
          '${DateFormat.jm(locale).format(entry.prayedAt)}';
      children.add(
        ListTile(
          key: Key('journal-entry-$i'),
          leading: const Icon(Icons.radio_button_checked_outlined),
          title: Text(
            entry.mode == RosaryMode.mysteriesOnly
                ? '${content.mysterySetTitle(entry.mysterySet).of(lang)} · ${l10n.modeMysteriesOnly}'
                : content.mysterySetTitle(entry.mysterySet).of(lang),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(when),
              if (entry.intention.isNotEmpty)
                Text(entry.intention, style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
          trailing: PopupMenuButton<bool>(
            key: Key('journal-menu-$i'),
            tooltip: l10n.journalEditIntention,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: true,
                child: Text(
                  entry.intention.isEmpty ? l10n.journalAddIntention : l10n.journalEditIntention,
                ),
              ),
              PopupMenuItem(value: false, child: Text(l10n.journalRemove)),
            ],
            onSelected: (edit) async {
              if (!edit) return journal.remove(entry);
              final text = await showIntentionDialog(context, initial: entry.intention);
              if (text != null) await journal.setIntention(entry, text);
            },
          ),
        ),
      );
    }
    if (entries.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('journal-clear'),
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.journalClear),
              onPressed: () => _confirmClear(context, journal),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.prayerJournal)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(padding: const EdgeInsets.only(bottom: 24), children: children),
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, JournalController journal) async {
    final l10n = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.journalClearConfirm),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('journal-clear-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.journalClear),
          ),
        ],
      ),
    );
    if (yes ?? false) await journal.clear();
  }
}
