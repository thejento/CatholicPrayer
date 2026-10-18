import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What kind of device the app runs on, used to adapt the layout.
@immutable
class DeviceProfile {
  const DeviceProfile({this.isTelevision = false, this.isAndroid = false});

  /// True on Android TV / Google TV, where the 10-foot UI applies (T-04).
  final bool isTelevision;

  /// True in the Android app (phone, tablet or TV), false on the web.
  final bool isAndroid;

  /// The daily reminder is offered on Android phones and tablets (DESIGN §3.8).
  bool get supportsReminders => isAndroid && !isTelevision;

  /// Platform channel implemented in `MainActivity.kt`.
  static const channel = MethodChannel('crc/device');

  /// Asks the platform whether this is a TV. Falls back to `false` on the
  /// web, other platforms, or if the channel is unavailable.
  static Future<DeviceProfile> detect({bool isAndroid = !kIsWeb}) async {
    if (!isAndroid || defaultTargetPlatform != TargetPlatform.android) {
      return const DeviceProfile();
    }
    try {
      final tv = await channel.invokeMethod<bool>('isTelevision') ?? false;
      return DeviceProfile(isTelevision: tv, isAndroid: true);
    } on PlatformException {
      return const DeviceProfile(isAndroid: true);
    } on MissingPluginException {
      return const DeviceProfile(isAndroid: true);
    }
  }
}
