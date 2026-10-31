import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/content_repository.dart';
import '../../domain/mysteries.dart';
import '../../domain/rosary_sequence.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/learn_page.dart';
import '../../providers/settings_controller.dart';
import '../../routes.dart';
import '../step_text.dart';
import 'learn_screen.dart';

/// Lets the person confirm today's suggested mysteries or choose another set.
class MysteryPickerScreen extends StatefulWidget {
  const MysteryPickerScreen({super.key, required this.initial});

  /// The suggested set, preselected and marked as such.
  final MysterySet initial;

  @override
  State<MysteryPickerScreen> createState() => _MysteryPickerScreenState();
}

class _MysteryPickerScreenState extends State<MysteryPickerScreen> {
  late MysterySet _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = context.read<ContentRepository>();
    final lang = contentLanguage(context);
    final settings = context.watch<SettingsController>();
    final mode = settings.rosaryMode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chooseMysteries)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.rosaryModeLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<RosaryMode>(
                key: const Key('rosary-mode'),
                segments: [
                  ButtonSegment(value: RosaryMode.guided, label: Text(l10n.modeGuided)),
                  ButtonSegment(
                    value: RosaryMode.mysteriesOnly,
                    label: Text(l10n.modeMysteriesOnly),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) => settings.setRosaryMode(s.first),
              ),
              const SizedBox(height: 8),
              Text(
                mode == RosaryMode.guided ? l10n.modeGuidedHint : l10n.modeMysteriesOnlyHint,
                key: const Key('rosary-mode-hint'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              LearnMoreButton(topic: LearnTopic.ways, subject: l10n.rosaryModeLabel),
              const SizedBox(height: 24),
              Text(l10n.chooseMysteriesHint, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              RadioGroup<MysterySet>(
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v!),
                child: Column(
                  children: [
                    for (final set in MysterySet.values)
                      Card(
                        child: Column(
                          children: [
                            RadioListTile<MysterySet>(
                              value: set,
                              title: Text(content.mysterySetTitle(set).of(lang)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (content.learnPage(LearnTopic.forSet(set)) case final page?)
                                    Text(
                                      page.summary.of(lang),
                                      key: Key('summary-${set.name}'),
                                      style: const TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  Text(
                                    content
                                        .mysteriesOf(set)
                                        .map((m) => m.title.of(lang))
                                        .join(' · '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              secondary: set == widget.initial
                                  ? Chip(label: Text(l10n.suggestedBadge))
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(start: 8, bottom: 4),
                              child: LearnMoreButton(
                                topic: LearnTopic.forSet(set),
                                subject: content.mysterySetTitle(set).of(lang),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Kept outside the list so Start is always visible (TV, small screens).
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: FilledButton.icon(
                autofocus: true,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.start),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: () => context.pushReplacement(Routes.rosary(_selected, mode), extra: 0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
