import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps helpyy listening for knocks while it is in the background, Android
/// only. See ListeningService.kt and BackgroundChannel.kt.
///
/// Does nothing on other platforms. iOS gives apps no way to keep reading
/// the motion sensor in the background, so it uses Back Tap instead.
class BackgroundListening {
  const BackgroundListening();

  static const _channel = MethodChannel('helpyy/background');

  /// Starts the foreground service with its "helpyy is listening"
  /// notification, asking for notification permission if needed.
  Future<void> start() => _invoke('start');

  Future<void> stop() => _invoke('stop');

  /// Brings the call screen up over whatever is showing, even the lock
  /// screen, when helpyy is not in front.
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

  // Listening in the foreground keeps working without the service, so a
  // failure here only costs the background part and is not shown to users.
  void _log(String message) {
    if (kDebugMode) debugPrint('[BackgroundListening] $message');
  }
}
