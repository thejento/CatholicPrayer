import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'audio/audio_catalog.dart';
import 'data/art_catalog.dart';
import 'audio/clip_player.dart';
import 'data/content_repository.dart';
import 'data/device_profile.dart';
import 'data/link_opener.dart';
import 'data/saints_repository.dart';
import 'data/scripture_repository.dart';
import 'domain/clock.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers/saved_session_controller.dart';
import 'providers/settings_controller.dart';
import 'providers/theme_manager.dart';
import 'reminders/reminder_controller.dart';
import 'reminders/reminder_sync.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

/// Root widget. All dependencies are passed in so tests can supply fakes.
class CatholicPrayerApp extends StatelessWidget {
  const CatholicPrayerApp({
    super.key,
    required this.content,
    required this.themeManager,
    required this.settings,
    required this.savedSession,
    required this.reminder,
    required this.scripture,
    required this.saints,
    this.device = const DeviceProfile(),
    this.audio = const AudioCatalog.empty(),
    this.playerFactory = JustAudioClipPlayer.new,
    this.clock = const Clock(),
    this.linkOpener = openInBrowser,
    this.art = const ArtCatalog.empty(),
  });

  final ContentRepository content;
  final ThemeManager themeManager;
  final SettingsController settings;
  final SavedSessionController savedSession;
  final ReminderController reminder;
  final ScriptureRepository scripture;
  final SaintsRepository saints;
  final DeviceProfile device;
  final AudioCatalog audio;

  /// Creates the audio player for a Rosary; tests pass a fake.
  final ClipPlayer Function() playerFactory;
  final Clock clock;

  /// Opens web links (the saint of the day); tests pass a fake.
  final LinkOpener linkOpener;

  /// Paintings for the mystery announcements (classic theme).
  final ArtCatalog art;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: content),
        Provider.value(value: scripture),
        Provider.value(value: saints),
        Provider.value(value: clock),
        Provider<LinkOpener>.value(value: linkOpener),
        Provider.value(value: device),
        Provider.value(value: audio),
        Provider.value(value: art),
        Provider<ClipPlayer Function()>.value(value: playerFactory),
        ChangeNotifierProvider.value(value: themeManager),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: savedSession),
        ChangeNotifierProvider.value(value: reminder),
      ],
      child: Consumer2<ThemeManager, SettingsController>(
        builder: (context, theme, settings, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeFor(theme.mode),
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => ReminderSync(child: child!),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
