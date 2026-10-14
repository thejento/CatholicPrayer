import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/data/content_repository.dart';
import 'src/data/preferences_store.dart';
import 'src/providers/settings_controller.dart';
import 'src/providers/theme_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SharedPreferencesStore();
  final themeManager = ThemeManager(store);
  final settings = SettingsController(store);
  final (content, _, _) = await (
    ContentRepository.load(rootBundle),
    themeManager.load(),
    settings.load(),
  ).wait;
  runApp(CatholicPrayerApp(content: content, themeManager: themeManager, settings: settings));
}
