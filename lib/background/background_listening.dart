import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BackgroundListening {
  const BackgroundListening();

  static const _channel = MethodChannel('helpyy/background');

  Future<void> start() => _invoke('start');

  Future<void> stop() => _invoke('stop');

  Future<void> showIncomingCall(String callerName) =>
      _invoke('showIncomingCall', {'callerName': callerName});

  Future<void> endIncomingCall() => _invoke('endIncomingCall');

  Future<void> _invoke(String method, [Object? arguments]) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod(method, arguments);
    } on PlatformException catch (e) {
      _log('$method failed: ${e.code} ${e.message}');
    } on MissingPluginException {
      _log('$method failed: no native side');
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[BackgroundListening] $message');
  }
}
