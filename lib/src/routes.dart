import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/content_repository.dart';
import 'domain/clock.dart';
import 'domain/mysteries.dart';
import 'domain/rosary_sequence.dart';
import 'providers/saved_session_controller.dart';
import 'ui/screens/about_today_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/mystery_picker_screen.dart';
import 'ui/screens/prayer_about_screen.dart';
import 'ui/screens/prayer_detail_screen.dart';
import 'ui/screens/prayer_library_screen.dart';
import 'ui/screens/rosary_screen.dart';
import 'ui/screens/scripture_screen.dart';
import 'ui/screens/settings_screen.dart';

/// Addresses of the screens (DESIGN §3.21). On the web they follow the
/// browser's address bar after `#`, so a refresh keeps the screen and a link
/// can open one, e.g. `#/library/hail_mary`. Every screen sits under Home, so
/// Back always leads there.
abstract final class Routes {
  static const home = '/';
  static const settings = '/settings';
  static const today = '/today';
  static const library = '/library';
  static const pray = '/pray';

  static String prayer(String id) => '/library/$id';
  static String aboutPrayer(String id) => '/library/$id/about';

  /// The Rosary: `/rosary/joyful`, `/rosary/joyful?mode=mysteriesOnly`.
  static String rosary(MysterySet set, RosaryMode mode) =>
      Uri(path: '/rosary/${set.name}', queryParameters: _mode(mode)).toString();

  /// A mystery's Bible passage, on top of its Rosary.
  static String passage(MysterySet set, RosaryMode mode, int decade) =>
      Uri(path: '/rosary/${set.name}/passage/$decade', queryParameters: _mode(mode)).toString();

  static Map<String, String>? _mode(RosaryMode mode) =>
      mode == RosaryMode.guided ? null : {'mode': mode.name};
}

/// Where a Rosary opens: the step passed by the app (`extra`), or, on a
/// refresh or a link, the saved step when it is the same Rosary (F-06).
int _startIndex(BuildContext context, GoRouterState state, MysterySet set, RosaryMode mode) {
  if (state.extra case final int index) return index;
  final saved = context.read<SavedSessionController>().saved;
  return saved != null && saved.mysterySet == set && saved.mode == mode ? saved.index : 0;
}

MysterySet? _set(GoRouterState state) =>
    MysterySet.values.where((s) => s.name == state.pathParameters['set']).firstOrNull;

RosaryMode _modeOf(GoRouterState state) =>
    RosaryMode.values.where((m) => m.name == state.uri.queryParameters['mode']).firstOrNull ??
    RosaryMode.guided;

GoRouter buildRouter() {
  // Screens opened on top of others (push) also show in the address bar.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  return _router();
}

GoRouter _router() => GoRouter(
  // An unknown address opens Home.
  onException: (_, _, router) => router.go(Routes.home),
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (_, _) => const HomeScreen(),
      routes: [
        GoRoute(path: 'settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: 'today',
          builder: (context, _) => AboutTodayScreen(date: context.read<Clock>().now()),
        ),
        GoRoute(
          path: 'pray',
          builder: (context, _) =>
              MysteryPickerScreen(initial: suggestedMysterySet(context.read<Clock>().now())),
        ),
        GoRoute(
          path: 'library',
          builder: (_, _) => const PrayerLibraryScreen(),
          routes: [
            GoRoute(
              path: ':id',
              redirect: (context, state) =>
                  context.read<ContentRepository>().prayer(state.pathParameters['id']!) == null
                  ? Routes.library
                  : null,
              builder: (context, state) => PrayerDetailScreen(
                prayer: context.read<ContentRepository>().prayer(state.pathParameters['id']!)!,
              ),
              routes: [
                GoRoute(
                  path: 'about',
                  builder: (context, state) => PrayerAboutScreen(
                    prayer: context.read<ContentRepository>().prayer(state.pathParameters['id']!)!,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'rosary/:set',
          redirect: (_, state) => _set(state) == null ? Routes.pray : null,
          builder: (context, state) {
            final set = _set(state)!;
            final mode = _modeOf(state);
            return RosaryScreen(
              mysterySet: set,
              mode: mode,
              startIndex: _startIndex(context, state, set, mode),
            );
          },
          routes: [
            GoRoute(
              path: 'passage/:decade',
              redirect: (_, state) {
                final decade = int.tryParse(state.pathParameters['decade']!);
                return decade == null || decade < 1 || decade > mysteriesPerSet
                    ? Routes.rosary(_set(state)!, _modeOf(state))
                    : null;
              },
              builder: (_, state) => ScriptureScreen(
                mysterySet: _set(state)!,
                decade: int.parse(state.pathParameters['decade']!),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
