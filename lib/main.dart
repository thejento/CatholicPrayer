import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/audio/audio_catalog.dart';
import 'src/data/art_catalog.dart';
import 'src/audio/voice_licenses.dart';
import 'src/data/content_repository.dart';
import 'src/data/device_profile.dart';
import 'src/data/preferences_store.dart';
import 'src/data/saints_repository.dart';
import 'src/data/scripture_repository.dart';
import 'src/data/scripture_licenses.dart';
import 'src/providers/saved_session_controller.dart';
import 'src/providers/settings_controller.dart';
import 'src/providers/theme_manager.dart';
import 'src/reminders/local_notifications_scheduler.dart';
import 'src/reminders/reminder_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerVoiceLicenses();
  registerScriptureLicenses();
  final store = SharedPreferencesStore();
  final themeManager = ThemeManager(store);
  final settings = SettingsController(store);
  final savedSession = SavedSessionController(store);
  final (content, scripture, saints, art, audio, device, _, _, _) = await (
    ContentRepository.load(rootBundle),
    ScriptureRepository.load(rootBundle),
    SaintsRepository.load(rootBundle),
    ArtCatalog.load(rootBundle),
    AudioCatalog.load(rootBundle),
    DeviceProfile.detect(),
    themeManager.load(),
    settings.load(),
    savedSession.load(),
  ).wait;
  final reminder = ReminderController(
    store,
    device.supportsReminders ? LocalNotificationsScheduler() : const NoReminderScheduler(),
    available: device.supportsReminders,
  );
  await reminder.load();
  registerArtLicenses(art);
  runApp(
    CatholicPrayerApp(
      content: content,
      themeManager: themeManager,
      settings: settings,
      savedSession: savedSession,
      reminder: reminder,
      scripture: scripture,
      saints: saints,
      art: art,
      device: device,
      audio: audio,
    ),
  );
}
