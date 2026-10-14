import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/content_repository.dart';
import 'domain/clock.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers/settings_controller.dart';
import 'providers/theme_manager.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

/// Root widget. All dependencies are passed in so tests can supply fakes.
class CatholicPrayerApp extends StatelessWidget {
  const CatholicPrayerApp({
    super.key,
    required this.content,
    required this.themeManager,
    required this.settings,
    this.clock = const Clock(),
  });

  final ContentRepository content;
  final ThemeManager themeManager;
  final SettingsController settings;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: content),
        Provider.value(value: clock),
        ChangeNotifierProvider.value(value: themeManager),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: Consumer2<ThemeManager, SettingsController>(
        builder: (context, theme, settings, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeFor(theme.mode),
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
