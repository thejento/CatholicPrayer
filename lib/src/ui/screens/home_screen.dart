import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/content_repository.dart';
import '../../domain/clock.dart';
import '../../domain/mysteries.dart';
import '../../l10n/generated/app_localizations.dart';
import '../step_text.dart';
import 'mystery_picker_screen.dart';
import 'prayer_library_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = contentLanguage(context);
    final suggested = suggestedMysterySet(context.read<Clock>().now());
    final setTitle = context.read<ContentRepository>().mysterySetTitle(suggested).of(lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.brightness_7_outlined, size: 72, color: theme.colorScheme.secondary),
                const SizedBox(height: 16),
                Text(
                  l10n.homeWelcome,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.today_outlined),
                    title: Text(l10n.suggestedToday),
                    subtitle: Text(setTitle, style: theme.textTheme.titleMedium),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  autofocus: true,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.beginRosary),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MysteryPickerScreen(initial: suggested),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(l10n.prayerLibrary),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => const PrayerLibraryScreen())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
