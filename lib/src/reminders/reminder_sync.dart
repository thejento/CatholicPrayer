import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../domain/mysteries.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/step_text.dart';
import 'reminder_controller.dart';

/// Hands the reminder its texts in the current language, so the schedule is
/// refreshed at start-up and whenever the language changes (DESIGN §3.8).
class ReminderSync extends StatefulWidget {
  const ReminderSync({super.key, required this.child});

  final Widget child;

  @override
  State<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends State<ReminderSync> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    final content = context.read<ContentRepository>();
    final lang = contentLanguage(context);
    // Each day's notification names that date's mysteries (r-12).
    unawaited(
      context.read<ReminderController>().updateTexts(
        ReminderTexts(
          title: l10n.reminderTitle,
          channelName: l10n.reminderChannel,
          bodies: {
            for (final set in MysterySet.values)
              set: l10n.reminderBody(content.mysterySetTitle(set).of(lang)),
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
