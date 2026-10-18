import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../domain/clock.dart';
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
    // Each weekday's text is for its next date, so Sundays follow the season.
    final now = context.read<Clock>().now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime next(int weekday) => today.add(Duration(days: (weekday - today.weekday) % 7));
    context.read<ReminderController>().updateTexts(
      ReminderTexts(
        title: l10n.reminderTitle,
        channelName: l10n.reminderChannel,
        bodies: {
          for (var d = DateTime.monday; d <= DateTime.sunday; d++)
            d: l10n.reminderBody(content.mysterySetTitle(suggestedMysterySet(next(d))).of(lang)),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
