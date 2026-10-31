import 'package:crc/src/data/content_repository.dart';
import 'package:crc/src/data/preferences_store.dart';
import 'package:crc/src/startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app.dart';

/// Every asset is malformed JSON.
class _BrokenBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList('{not json'.codeUnits));
}

/// Storage that fails, as in a private browser window.
class _FailingStore extends InMemoryPreferencesStore {
  @override
  Future<bool?> getBool(String key) => Future.error(StateError('storage disabled'));
}

/// Startup errors (r-13).
void main() {
  testWidgets('broken content shows an error screen, not a blank one', (tester) async {
    final app = await startApp(() async {
      await ContentRepository.load(_BrokenBundle());
      return const SizedBox();
    });
    expect(app, isA<StartupErrorApp>());
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(find.text("The app couldn't start"), findsOneWidget);
    expect(find.byKey(const Key('startup-failed')), findsOneWidget);
    expect(find.textContaining('github.com/thejento/CatholicPrayer/issues'), findsOneWidget);
  });

  testWidgets('a successful start returns the app', (tester) async {
    final app = await startApp(() async => const Text('ok', textDirection: TextDirection.ltr));
    expect(app, isA<Text>());
  });

  test('storage that fails is replaced by memory, so the app still opens', () async {
    expect(await openPreferences(_FailingStore()), isA<InMemoryPreferencesStore>());
    final working = InMemoryPreferencesStore();
    expect(await openPreferences(working), same(working));
  });

  test('an unknown saint id gives the id instead of failing', () {
    expect(loadRealSaints().name('no_such_saint', 'fr'), 'no_such_saint');
  });
}
