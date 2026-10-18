import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/content_repository.dart';
import '../../data/device_profile.dart';
import '../../data/scripture_repository.dart';
import '../../domain/mysteries.dart';
import '../step_text.dart';

/// The Bible passage of a mystery, to read before meditating (DESIGN §3.9).
class ScriptureScreen extends StatelessWidget {
  const ScriptureScreen({super.key, required this.mysterySet, required this.decade});

  final MysterySet mysterySet;
  final int decade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = contentLanguage(context);
    final mystery = context.read<ContentRepository>().mystery(mysterySet, decade);
    final passage = context.read<ScriptureRepository>().passage(mysterySet, decade, lang)!;
    // On TV the D-pad moves from verse to verse, scrolling as it goes.
    final tv = context.read<DeviceProfile>().isTelevision;
    final verseStyle = theme.textTheme.titleLarge?.copyWith(height: 1.5);
    final numberStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      appBar: AppBar(title: Text(mystery.title.of(lang))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Semantics(
                header: true,
                child: Text(
                  mystery.scripture.of(lang),
                  key: const Key('passage-reference'),
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              for (final (i, verse) in passage.verses.indexed)
                Focus(
                  autofocus: tv && i == 0,
                  canRequestFocus: tv,
                  child: Builder(
                    builder: (context) {
                      final focused = Focus.of(context).hasFocus;
                      return Container(
                        key: Key('verse-${verse.number}'),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: focused ? theme.colorScheme.secondaryContainer : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${verse.number}  ', style: numberStyle),
                              TextSpan(text: verse.text),
                            ],
                          ),
                          style: verseStyle,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Text(passage.source, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
