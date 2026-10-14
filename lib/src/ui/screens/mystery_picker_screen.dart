import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/content_repository.dart';
import '../../domain/mysteries.dart';
import '../../l10n/generated/app_localizations.dart';
import '../step_text.dart';
import 'rosary_screen.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chooseMysteries)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.chooseMysteriesHint, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              RadioGroup<MysterySet>(
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v!),
                child: Column(
                  children: [
                    for (final set in MysterySet.values)
                      Card(
                        child: RadioListTile<MysterySet>(
                          value: set,
                          title: Text(content.mysterySetTitle(set).of(lang)),
                          subtitle: Text(
                            content.mysteriesOf(set).map((m) => m.title.of(lang)).join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondary: set == widget.initial
                              ? Chip(label: Text(l10n.suggestedBadge))
                              : null,
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
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => RosaryScreen(mysterySet: _selected)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
