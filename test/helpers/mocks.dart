import 'package:helpyy/auth/data/auth_repository.dart';
import 'package:helpyy/background/background_listening.dart';
import 'package:helpyy/calls/data/call_log_repository.dart';
import 'package:helpyy/knock/back_tap_shortcuts.dart';
import 'package:helpyy/knock/data/pattern_repository.dart';
import 'package:helpyy/knock/knock_detector.dart';
import 'package:helpyy/ringtone/ringtone_player.dart';
import 'package:helpyy/settings/data/settings_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockPatternRepository extends Mock implements PatternRepository {}

class MockKnockDetector extends Mock implements KnockDetector {}

class MockCallLogRepository extends Mock implements CallLogRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockRingtonePlayer extends Mock implements RingtonePlayer {}

MockRingtonePlayer silentRingtonePlayer() {
  final player = MockRingtonePlayer();
  when(
    () => player.play(any(), loop: any(named: 'loop')),
  ).thenAnswer((_) async {});
  when(player.stop).thenAnswer((_) async {});
  when(() => player.pick(any())).thenAnswer((_) async => null);
  return player;
}

class MockBackgroundListening extends Mock implements BackgroundListening {}

MockBackgroundListening quietBackgroundListening() {
  final background = MockBackgroundListening();
  when(background.start).thenAnswer((_) async {});
  when(background.stop).thenAnswer((_) async {});
  when(() => background.showIncomingCall(any())).thenAnswer((_) async {});
  when(background.endIncomingCall).thenAnswer((_) async {});
  return background;
}

class MockBackTapShortcuts extends Mock implements BackTapShortcuts {}
