import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BackTapShortcuts {
  const BackTapShortcuts();

  static const _channel = MethodChannel('helpyy/back_tap');

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

  void _log(String message) {
    if (kDebugMode) debugPrint('[BackTapShortcuts] failed: $message');
  }
}
