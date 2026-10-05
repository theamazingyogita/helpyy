import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Taps that arrive through iOS Back Tap, iOS only. See the App Intents in
/// AppDelegate.swift.
///
/// iOS does not let apps read the motion sensor in the background. Back Tap
/// does work everywhere, so the user points its double or triple tap at a
/// helpyy shortcut, and the shortcut opens helpyy with the tap count.
class BackTapShortcuts {
  const BackTapShortcuts();

  static const _channel = MethodChannel('helpyy/back_tap');

  /// 2 for a double tap, 3 for a triple tap. A tap that launched helpyy is
  /// delivered as soon as this is listened to.
  Stream<int> taps() {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const Stream.empty();
    }
    late final StreamController<int> controller;
    controller = StreamController(
      onListen: () async {
        _channel.setMethodCallHandler((call) async {
          if (call case MethodCall(method: 'tapped', arguments: final int n)) {
            controller.add(n);
          }
        });
        try {
          final pending = await _channel.invokeMethod<int>('ready');
          if (pending != null) controller.add(pending);
        } on PlatformException catch (e) {
          _log('${e.code} ${e.message}');
        } on MissingPluginException {
          _log('no native side');
        }
      },
      onCancel: () => _channel.setMethodCallHandler(null),
    );
    return controller.stream;
  }

  // Without the native side Back Tap just does nothing. Signals still work
  // while helpyy is open, so there is nothing to show the user.
  void _log(String message) {
    if (kDebugMode) debugPrint('[BackTapShortcuts] failed: $message');
  }
}
