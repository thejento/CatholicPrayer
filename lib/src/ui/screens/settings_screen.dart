import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_info.dart';
import '../../audio/audio_catalog.dart';
import '../../data/device_profile.dart';
import '../../domain/liturgical_calendar.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/journal_controller.dart';
import '../../providers/settings_controller.dart';
import '../../providers/theme_manager.dart';
import '../../reminders/reminder_controller.dart';
import '../../theme/app_theme.dart';
import '../liturgy_text.dart';
import '../open_link.dart';

/// Native names, so a person can find their language whatever the UI language.
const Map<String, String> _languageNames = {'en': 'English', 'es': 'Español', 'fr': 'Français'};

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.watch<ThemeManager>();
    final settings = context.watch<SettingsController>();
    final reminder = context.watch<ReminderController>();
    final device = context.read<DeviceProfile>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.appearance, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<AppThemeMode>(
                segments: [
                  ButtonSegment(value: AppThemeMode.classic, label: Text(l10n.themeClassic)),
                  ButtonSegment(
                    value: AppThemeMode.kidFriendly,
                    label: Text(l10n.themeKidFriendly),
                  ),
                ],
                selected: {theme.mode},
                onSelectionChanged: (s) => theme.setMode(s.first),
              ),
              if (theme.mode == AppThemeMode.classic)
                SwitchListTile(
                  key: const Key('follow-season'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.followSeason),
                  subtitle: Text(l10n.followSeasonHint),
                  value: theme.followSeason,
                  onChanged: theme.setFollowSeason,
                ),
              const SizedBox(height: 24),
              Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButton<String?>(
                key: const Key('language-dropdown'),
                isExpanded: true,
                value: settings.locale?.languageCode,
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.languageSystem)),
                  for (final e in _languageNames.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (code) => settings.setLocale(code == null ? null : Locale(code)),
              ),
              const SizedBox(height: 24),
              Text(l10n.calendarLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButton<CalendarRegion>(
                key: const Key('calendar-dropdown'),
                isExpanded: true,
                value: settings.calendarRegion,
                items: [
                  for (final r in CalendarRegion.values)
                    DropdownMenuItem(value: r, child: Text(calendarName(l10n, r))),
                ],
                onChanged: (r) => settings.setCalendarRegion(r!),
              ),
              Text(l10n.calendarHint, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.showGuidance),
                subtitle: Text(l10n.showGuidanceSubtitle),
                value: settings.showGuidance,
                onChanged: settings.setShowGuidance,
              ),
              const SizedBox(height: 16),
              Text(l10n.voiceSection, style: Theme.of(context).textTheme.titleMedium),
              if (!context.read<AudioCatalog>().hasLanguage(
                Localizations.localeOf(context).languageCode,
              ))
                Padding(padding: const EdgeInsets.only(top: 8), child: Text(l10n.voiceUnavailable))
              else ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.readAloud),
                  value: settings.voiceEnabled,
                  onChanged: settings.setVoiceEnabled,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.readGuidanceAloud),
                  subtitle: Text(l10n.readGuidanceAloudSubtitle),
                  value: settings.readGuidanceAloud,
                  onChanged: settings.setReadGuidanceAloud,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.autoAdvance),
                  subtitle: Text(l10n.autoAdvanceSubtitle),
                  value: settings.autoAdvance,
                  onChanged: settings.setAutoAdvance,
                ),
                SwitchListTile(
                  key: const Key('auto-scroll'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.autoScroll),
                  subtitle: Text(l10n.autoScrollSubtitle),
                  value: settings.autoScroll,
                  onChanged: settings.setAutoScroll,
                ),
                Text(l10n.pauseLabel(settings.pauseSeconds)),
                Slider(
                  key: const Key('pause-slider'),
                  min: SettingsController.minPause.toDouble(),
                  max: SettingsController.maxPause.toDouble(),
                  divisions: SettingsController.maxPause - SettingsController.minPause,
                  value: settings.pauseSeconds.toDouble(),
                  label: '${settings.pauseSeconds} s',
                  onChanged: (v) => settings.setPauseSeconds(v.round()),
                ),
              ],
              if (reminder.available) ...[
                const SizedBox(height: 16),
                Text(l10n.reminderSection, style: Theme.of(context).textTheme.titleMedium),
                SwitchListTile(
                  key: const Key('reminder-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.reminderSwitch),
                  subtitle: Text(l10n.reminderSubtitle),
                  value: reminder.enabled,
                  onChanged: (on) async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (!await reminder.setEnabled(on)) {
                      messenger.showSnackBar(SnackBar(content: Text(l10n.reminderDenied)));
                    }
                  },
                ),
                ListTile(
                  key: const Key('reminder-time'),
                  contentPadding: EdgeInsets.zero,
                  enabled: reminder.enabled,
                  leading: const Icon(Icons.schedule),
                  title: Text(l10n.reminderTime),
                  trailing: Text(
                    reminder.time.format(context),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: reminder.time,
                    );
                    if (picked != null) await reminder.setTime(picked);
                  },
                ),
              ],
              const SizedBox(height: 16),
              Text(l10n.prayerJournal, style: Theme.of(context).textTheme.titleMedium),
              SwitchListTile(
                key: const Key('journal-switch'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.journalSwitch),
                subtitle: Text(l10n.journalSwitchHint),
                value: context.watch<JournalController>().enabled,
                onChanged: context.read<JournalController>().setEnabled,
              ),
              const Divider(height: 32),
              Text(l10n.about, style: Theme.of(context).textTheme.titleMedium),
              ListTile(
                key: const Key('settings-version'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tag),
                title: Text(l10n.appVersion(versionLabel)),
              ),
              // On TV there is rarely a browser, so the address is shown instead (DESIGN §3.14).
              ListTile(
                key: const Key('settings-issues'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(l10n.reportIssueLink),
                subtitle: device.isTelevision ? SelectableText(issuesUrl.toString()) : null,
                trailing: device.isTelevision ? null : const Icon(Icons.open_in_new),
                onTap: device.isTelevision ? null : () => openLink(context, issuesUrl),
              ),
              if (playStoreListed && device.isAndroid && !device.isTelevision)
                ListTile(
                  key: const Key('settings-rate'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.star_outline),
                  title: Text(l10n.rateOnPlay),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => openLink(context, playStoreUrl),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutAndCredits),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                  applicationVersion: versionLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
