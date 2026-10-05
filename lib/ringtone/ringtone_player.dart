import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ringtone.dart';

/// Plays ringtones through the native side, see RingtoneChannel.kt and
/// AppDelegate.swift.
///
/// Every call throws [PlatformException] when the platform cannot do it,
/// including when the native side is missing from the build.
class RingtonePlayer {
  const RingtonePlayer();

  static const _channel = MethodChannel('helpyy/ringtone');

  /// Null rings the phone's default ringtone on Android and the first
  /// bundled tone on iOS.
  Future<void> play(Ringtone? ringtone, {bool loop = true}) {
    final id = switch (ringtone) {
      final Ringtone tone => tone.id,
      null when defaultTargetPlatform == TargetPlatform.iOS =>
        Ringtone.bundled.first.id,
      null => null,
    };
    return _invoke(
      () => _channel.invokeMethod('play', {'id': id, 'loop': loop}),
    );
  }

  Future<void> stop() => _invoke(() => _channel.invokeMethod('stop'));

  /// Opens the system ringtone picker, Android only. Null when the user
  /// backs out without choosing.
  Future<Ringtone?> pick(Ringtone? current) async {
    final picked = await _invoke(
      () =>
          _channel.invokeMapMethod<String, String>('pick', {'id': current?.id}),
    );
    if (picked == null) return null;
    return Ringtone(id: picked['id']!, title: picked['title']!);
  }

  Future<T> _invoke<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on MissingPluginException catch (e) {
      _log('MISSING ${e.message}');
      throw PlatformException(code: 'MISSING', message: e.message);
    } on PlatformException catch (e) {
      _log('${e.code} ${e.message}');
      rethrow;
    }
  }

  // Failures are handled by the callers, which keep the call vibrating, so
  // this is the only place they show up while testing on a phone.
  void _log(String message) {
    if (kDebugMode) debugPrint('[RingtonePlayer] failed: $message');
  }
}
