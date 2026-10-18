import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/content_repository.dart';
import '../../domain/liturgical_calendar.dart';
import '../../domain/mysteries.dart';
import '../../l10n/generated/app_localizations.dart';
import '../liturgy_text.dart';
import '../step_text.dart';

/// Explains the day: its season and colour, why these mysteries are suggested,
/// and what each set of mysteries is about (DESIGN §3.10).
class AboutTodayScreen extends StatelessWidget {
  const AboutTodayScreen({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = contentLanguage(context);
    final content = context.read<ContentRepository>();
    final day = liturgicalDay(date);
    final today = suggestedMysterySet(date);
    String setTitle(MysterySet s) => content.mysterySetTitle(s).of(lang);

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
        ),
      ),
    );
    Widget para(String text, {Key? key}) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, key: key, style: theme.textTheme.bodyLarge),
    );

    // "Monday and Saturday: Joyful Mysteries", from the weekday rule itself.
    final weekdayFormat = DateFormat.EEEE(lang);
    // A week of Ordinary Time, so Sunday shows its usual set; the seasonal
    // Sundays are explained just below.
    final monday = DateTime(2026, 10, 12);
    final byWeekday = <MysterySet, List<String>>{};
    for (var i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final name = weekdayFormat.format(d);
      (byWeekday[suggestedMysterySet(d)] ??= []).add(name[0].toUpperCase() + name.substring(1));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutToday)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              section(l10n.aboutSeasonSection),
              Text(
                liturgicalDayName(l10n, day, lang),
                key: const Key('about-day-name'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              para(seasonAbout(l10n, day.season), key: const Key('about-season')),
              section(l10n.aboutColorSection),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 12),
                    child: ColorDot(color: liturgicalColor(day.color)),
                  ),
                  Expanded(child: para(colorAbout(l10n, day.color), key: const Key('about-color'))),
                ],
              ),
              section(l10n.aboutMysteriesSection),
              para(l10n.aboutTodaySet(setTitle(today)), key: const Key('about-today-set')),
              if (sundayMysteriesNote(l10n, date, day) case final note?) para(note),
              para(l10n.aboutMysteriesIntro),
              for (final MapEntry(key: set, value: days) in byWeekday.entries)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    '• ${days.join(' · ')}: ${setTitle(set)}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              const SizedBox(height: 8),
              para(l10n.aboutSundayRule),
              para(l10n.aboutAnyDay),
              section(l10n.aboutSetsSection),
              for (final set in MysterySet.values) ...[
                Text(setTitle(set), style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                para(setAbout(l10n, set)),
                for (final m in content.mysteriesOf(set))
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 2),
                    child: Text(
                      '${m.number}. ${m.title.of(lang)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
