import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ringtone.dart';

class RingtonePlayer {
  const RingtonePlayer();

  static const _channel = MethodChannel('helpyy/ringtone');

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

  void _log(String message) {
    if (kDebugMode) debugPrint('[RingtonePlayer] failed: $message');
  }
}
