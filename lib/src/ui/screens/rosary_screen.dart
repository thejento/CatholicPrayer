import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/content_repository.dart';
import '../../data/device_profile.dart';
import '../../domain/mysteries.dart';
import '../../domain/rosary_sequence.dart';
import '../../domain/rosary_session.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/saved_session_controller.dart';
import '../../providers/settings_controller.dart';
import '../step_text.dart';
import '../widgets/rosary_beads.dart';

/// The guided Rosary: bead drawing, prayer text and newcomer guidance.
class RosaryScreen extends StatefulWidget {
  const RosaryScreen({super.key, required this.mysterySet, this.startIndex = 0});

  final MysterySet mysterySet;

  /// Step to start on, when resuming an unfinished Rosary.
  final int startIndex;

  @override
  State<RosaryScreen> createState() => _RosaryScreenState();
}

class _RosaryScreenState extends State<RosaryScreen> {
  late final RosarySession _session = RosarySession(
    mysterySet: widget.mysterySet,
    startIndex: widget.startIndex,
  );
  late final SavedSessionController _saved = context.read<SavedSessionController>();

  @override
  void initState() {
    super.initState();
    _session.addListener(_persist);
  }

  /// Remembers progress so the Rosary can be resumed later (F-06).
  void _persist() {
    if (_session.isFinished) {
      _saved.clear();
    } else {
      _saved.save(SavedSession(mysterySet: widget.mysterySet, index: _session.index));
    }
  }

  @override
  void dispose() {
    _session
      ..removeListener(_persist)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Left/right arrows (keyboard, Android TV D-pad) move through the
    // sequence; Enter/Select activate the focused button (Next by default).
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowRight): _session.next,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _session.previous,
      },
      child: Focus(
        child: ListenableBuilder(
          listenable: _session,
          builder: (context, _) => Scaffold(
            appBar: AppBar(
              title: Text(
                context
                    .read<ContentRepository>()
                    .mysterySetTitle(widget.mysterySet)
                    .of(contentLanguage(context)),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: _session.progress),
              ),
            ),
            body: SafeArea(
              child: _session.isFinished
                  ? _CompletionView(onPrayAgain: _session.restart, onBack: _session.previous)
                  : _StepLayout(session: _session, l10n: l10n),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({required this.session, required this.l10n});

  final RosarySession session;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final step = session.current;
    final visited = {for (var i = 0; i < session.index; i++) session.steps[i].bead};
    final beads = RosaryBeads(
      current: step.bead,
      visited: visited,
      onCurrentBeadTap: session.next,
      semanticLabel: l10n.beadSemantics(step.bead + 1, beadCount),
    );
    final panel = _StepPanel(session: session, l10n: l10n);
    final controls = _Controls(session: session, l10n: l10n);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600 && !context.read<DeviceProfile>().isTelevision) {
          return Column(
            children: [
              SizedBox(height: constraints.maxHeight * 0.32, child: beads),
              Expanded(child: panel),
              controls,
            ],
          );
        }
        // 10-foot UI on TV (T-04) and on very wide windows.
        final large = constraints.maxWidth >= 1200 || context.read<DeviceProfile>().isTelevision;
        return MediaQuery(
          data: large
              ? MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(MediaQuery.textScalerOf(context).scale(1.3)),
                )
              : MediaQuery.of(context),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(padding: const EdgeInsets.all(16), child: beads),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(child: panel),
                    controls,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepPanel extends StatelessWidget {
  const _StepPanel({required this.session, required this.l10n});

  final RosarySession session;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = context.read<ContentRepository>();
    final showGuidance = context.watch<SettingsController>().showGuidance;
    final lang = contentLanguage(context);
    final step = session.current;

    final String title;
    final List<Widget> body;
    if (step.kind == StepKind.announceMystery) {
      final mystery = content.mystery(session.mysterySet, step.decade!);
      title = mystery.title.of(lang);
      body = [
        Text(l10n.scriptureLabel(mystery.scripture.of(lang)), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(l10n.fruitLabel(mystery.fruit.of(lang)), style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        Text(l10n.meditateHint, style: theme.textTheme.bodyLarge),
      ];
    } else {
      final prayer = content.prayer(step.prayerId!)!;
      final count = step.count;
      final total = step.part == RosaryPart.introduction ? 3 : 10;
      title = count == null
          ? prayer.titleFor(lang)
          : '${prayer.titleFor(lang)} (${l10n.hailMaryCount(count, total)})';
      body = [
        SelectableText(
          prayer.textFor(lang),
          style: theme.textTheme.headlineSmall?.copyWith(height: 1.4),
        ),
      ];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${partLabel(l10n, step)} · ${l10n.stepCounter(session.index + 1, session.length)}',
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(title, key: const Key('step-title'), style: theme.textTheme.headlineMedium),
          if (showGuidance) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('step-guidance'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: theme.colorScheme.onSecondaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      guidanceFor(l10n, step),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          ...body,
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.session, required this.l10n});

  final RosarySession session;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chevron_left),
              label: Text(l10n.previous),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              // Always enabled so D-pad focus never lands on a disabled control.
              onPressed: session.previous,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              autofocus: true,
              icon: const Icon(Icons.chevron_right),
              label: Text(l10n.next),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: session.next,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.onPrayAgain, required this.onBack});

  final VoidCallback onPrayAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.favorite, size: 72, color: theme.colorScheme.secondary),
              const SizedBox(height: 16),
              Text(
                l10n.completeTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.completeMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                autofocus: true,
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(l10n.backToHome),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onPrayAgain, child: Text(l10n.prayAgain)),
            ],
          ),
        ),
      ),
    );
  }
}
