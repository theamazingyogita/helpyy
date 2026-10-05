import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/knock/back_tap_shortcuts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('helpyy/back_tap');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('delivers the tap that launched the app, then later ones', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return call.method == 'ready' ? 3 : null;
    });
    final taps = <int>[];
    final subscription = const BackTapShortcuts().taps().listen(taps.add);
    await Future<void>.delayed(Duration.zero);

    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall('tapped', 2)),
      (_) {},
    );

    expect(taps, [3, 2]);
    await subscription.cancel();
  });

  test('stays quiet when the native side is missing', () async {
    final taps = await const BackTapShortcuts()
        .taps()
        .take(1)
        .toList()
        .timeout(const Duration(milliseconds: 100), onTimeout: () => const []);
    expect(taps, isEmpty);
  });

  test('is empty on Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(await const BackTapShortcuts().taps().toList(), isEmpty);
  });
}
