import 'package:crc/src/data/preferences_store.dart';
import 'package:crc/src/domain/mysteries.dart';
import 'package:crc/src/providers/saved_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavedSession', () {
    test('round-trips through encode/decode', () {
      const s = SavedSession(mysterySet: MysterySet.luminous, index: 42);
      expect(SavedSession.decode(s.encode()), s);
    });

    for (final bad in [null, '', 'joyful', 'unknown:3', 'joyful:x', 'joyful:-1', 'a:b:c']) {
      test('rejects "$bad"', () => expect(SavedSession.decode(bad), isNull));
    }
  });

  group('SavedSessionController', () {
    test('saves, reloads and clears', () async {
      final store = InMemoryPreferencesStore();
      final controller = SavedSessionController(store);
      await controller.load();
      expect(controller.saved, isNull);

      const s = SavedSession(mysterySet: MysterySet.glorious, index: 10);
      await controller.save(s);
      expect(store.values[SavedSessionController.prefsKey], 'glorious:10');

      final reloaded = SavedSessionController(store);
      await reloaded.load();
      expect(reloaded.saved, s);

      await reloaded.clear();
      expect(reloaded.saved, isNull);
      expect(store.values, isEmpty);
    });

    test('being on the first step is not worth resuming', () async {
      final controller = SavedSessionController(InMemoryPreferencesStore());
      await controller.save(const SavedSession(mysterySet: MysterySet.joyful, index: 5));
      await controller.save(const SavedSession(mysterySet: MysterySet.joyful, index: 0));
      expect(controller.saved, isNull);
    });

    test('does not notify when nothing changes', () async {
      final controller = SavedSessionController(InMemoryPreferencesStore());
      var calls = 0;
      controller.addListener(() => calls++);
      await controller.clear();
      const s = SavedSession(mysterySet: MysterySet.joyful, index: 3);
      await controller.save(s);
      await controller.save(s);
      expect(calls, 1);
    });
  });
}
