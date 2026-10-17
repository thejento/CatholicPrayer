import 'package:crc/src/data/device_profile.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void mockChannel(Future<Object?>? Function(MethodCall call)? handler) {
    messenger.setMockMethodCallHandler(DeviceProfile.channel, handler);
    addTearDown(() => messenger.setMockMethodCallHandler(DeviceProfile.channel, null));
  }

  test('reports a TV when the platform says so', () async {
    mockChannel((call) async => call.method == 'isTelevision');
    expect((await DeviceProfile.detect(isAndroid: true)).isTelevision, isTrue);
  });

  test('reports a phone when the platform says so', () async {
    mockChannel((call) async => false);
    expect((await DeviceProfile.detect(isAndroid: true)).isTelevision, isFalse);
  });

  test('falls back to phone on platform errors', () async {
    mockChannel((call) async => throw PlatformException(code: 'boom'));
    expect((await DeviceProfile.detect(isAndroid: true)).isTelevision, isFalse);
  });

  test('falls back to phone when the channel is missing', () async {
    expect((await DeviceProfile.detect(isAndroid: true)).isTelevision, isFalse);
  });

  test('never asks the platform on the web', () async {
    var asked = false;
    mockChannel((call) async => asked = true);
    expect((await DeviceProfile.detect(isAndroid: false)).isTelevision, isFalse);
    expect(asked, isFalse);
  });

  test('offers reminders on Android phones only', () async {
    mockChannel((call) async => false);
    final phone = await DeviceProfile.detect(isAndroid: true);
    expect(phone.isAndroid, isTrue);
    expect(phone.supportsReminders, isTrue);

    mockChannel((call) async => true);
    expect((await DeviceProfile.detect(isAndroid: true)).supportsReminders, isFalse);
    expect((await DeviceProfile.detect(isAndroid: false)).supportsReminders, isFalse);
  });
}
