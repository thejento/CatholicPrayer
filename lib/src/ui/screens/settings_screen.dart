import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/settings_controller.dart';
import '../../providers/theme_manager.dart';
import '../../theme/app_theme.dart';

/// Native names, so a person can find their language whatever the UI language.
const Map<String, String> _languageNames = {'en': 'English', 'es': 'Español', 'fr': 'Français'};

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.watch<ThemeManager>();
    final settings = context.watch<SettingsController>();

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
              const Divider(height: 32),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutAndCredits),
                onTap: () => showLicensePage(context: context, applicationName: l10n.appTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
