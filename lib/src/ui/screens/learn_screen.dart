import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/content_repository.dart';
import '../../data/device_profile.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/learn_page.dart';
import '../../providers/settings_controller.dart';
import '../../routes.dart';
import '../step_text.dart';

/// Opens the page teaching [topic]. [subject] names it for screen readers,
/// since several "Learn more" buttons can share a screen.
class LearnMoreButton extends StatelessWidget {
  const LearnMoreButton({super.key, required this.topic, required this.subject});

  final LearnTopic topic;
  final String subject;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).learnMore;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        label: '$label: $subject',
        button: true,
        excludeSemantics: true,
        child: TextButton.icon(
          key: Key('learn-${topic.slug}'),
          icon: const Icon(Icons.school_outlined),
          label: Text(label),
          onPressed: () => context.push(Routes.learnTopic(topic)),
        ),
      ),
    );
  }
}

/// The list of topics (DESIGN §3.23).
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  static const _groups = [
    [
      LearnTopic.rosary,
      LearnTopic.joyful,
      LearnTopic.luminous,
      LearnTopic.sorrowful,
      LearnTopic.glorious,
    ],
    [LearnTopic.divineMercy],
    [LearnTopic.ways, LearnTopic.ending],
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final content = context.read<ContentRepository>();
    final lang = contentLanguage(context);
    final headings = [l10n.learnGroupRosary, l10n.learnGroupOther, l10n.learnGroupApp];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.learnTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(l10n.learnIntro, style: theme.textTheme.bodyLarge),
              ),
              for (final (g, topics) in _groups.indexed) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Semantics(
                    header: true,
                    child: Text(
                      headings[g],
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                for (final topic in topics)
                  if (content.learnPage(topic) case final page?)
                    ListTile(
                      key: Key('topic-${topic.slug}'),
                      autofocus: topic == LearnTopic.rosary,
                      title: Text(page.title.of(lang)),
                      subtitle: Text(page.summary.of(lang)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(Routes.learnTopic(topic)),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One topic: its sections, then the mysteries and a way to start praying.
class LearnTopicScreen extends StatelessWidget {
  const LearnTopicScreen({super.key, required this.topic});

  final LearnTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final lang = contentLanguage(context);
    final content = context.read<ContentRepository>();
    final page = content.learnPage(topic)!;
    // On TV the D-pad moves from section to section, scrolling as it goes.
    final tv = context.read<DeviceProfile>().isTelevision;
    final set = topic.mysterySet;
    final sections = [
      for (final s in page.sections) (s.heading.of(lang), s.text.of(lang)),
      if (set != null)
        (
          l10n.learnMysteries,
          [
            for (final m in content.mysteriesOf(set))
              '${m.number}. ${m.title.of(lang)}\n${l10n.fruitLabel(m.fruit.of(lang))}',
          ].join('\n\n'),
        ),
    ];
    final (label, route, extra) = switch (topic) {
      LearnTopic.divineMercy => (l10n.prayChaplet, Routes.divineMercy, null),
      LearnTopic.ending => (l10n.settings, Routes.settings, null),
      _ when set != null => (
        l10n.prayTheseMysteries,
        Routes.rosary(set, context.read<SettingsController>().rosaryMode),
        0,
      ),
      _ => (l10n.beginRosary, Routes.pray, null),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.learnTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Semantics(
                header: true,
                child: Text(page.title.of(lang), style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: 8),
              Text(
                page.summary.of(lang),
                style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
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
                            key: Key('learn-section-$i'),
                            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Align(
                child: FilledButton(
                  key: const Key('learn-action'),
                  onPressed: () => context.push(route, extra: extra),
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
