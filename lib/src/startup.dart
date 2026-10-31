import 'package:flutter/material.dart';

import 'app_info.dart';
import 'data/preferences_store.dart';
import 'l10n/generated/app_localizations.dart';

/// [preferred], or an in-memory store when it doesn't work (storage turned
/// off in a private browser window, for instance): the app still opens,
/// it just doesn't remember settings (r-13).
Future<PreferencesStore> openPreferences(PreferencesStore preferred) async {
  try {
    await preferred.getBool('probe');
    return preferred;
  } catch (error) {
    debugPrint('Preferences unavailable ($error); settings will not be kept');
    return InMemoryPreferencesStore();
  }
}

/// Runs [load] and returns the app it builds, or an error screen if loading
/// fails, instead of leaving a blank screen (r-13).
Future<Widget> startApp(Future<Widget> Function() load) async {
  try {
    return await load();
  } catch (error, stack) {
    debugPrint('Startup failed: $error\n$stack');
    return const StartupErrorApp();
  }
}

/// Says the app couldn't start, and where to report it.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    home: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final theme = Theme.of(context);
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      l10n.startupFailedTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.startupFailedMessage,
                      key: const Key('startup-failed'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    SelectableText(issuesUrl.toString(), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
