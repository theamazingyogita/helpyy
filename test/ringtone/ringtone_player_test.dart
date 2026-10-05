import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/ringtone/ringtone.dart';
import 'package:helpyy/ringtone/ringtone_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('helpyy/ringtone');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('a build without the native side fails as a PlatformException', () {
    expect(
      const RingtonePlayer().play(Ringtone.bundled.first),
      throwsA(isA<PlatformException>()),
    );
  });

  test('sends the tone and whether to loop', () async {
    MethodCall? sent;
    messenger.setMockMethodCallHandler(channel, (call) async {
      sent = call;
      return null;
    });

    await const RingtonePlayer().play(Ringtone.bundled.last, loop: false);

    expect(sent?.method, 'play');
    expect(sent?.arguments, {'id': Ringtone.bundled.last.id, 'loop': false});
  });

  test('turns what the picker returns into a ringtone', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {'id': 'content://media/7', 'title': 'Beep Once'},
    );

    expect(
      await const RingtonePlayer().pick(null),
      const Ringtone(id: 'content://media/7', title: 'Beep Once'),
    );
  });
}
