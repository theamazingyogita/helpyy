import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/ringtone/ringtone.dart';
import 'package:helpyy/settings/bloc/settings_bloc.dart';
import 'package:helpyy/settings/data/local_settings_repository.dart';
import 'package:helpyy/settings/motion_sensitivity.dart';
import 'package:helpyy/storage/storage_write_exception.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mocks.dart';

void main() {
  late MockSettingsRepository repository;
  late MockRingtonePlayer player;
  final classic = Ringtone.bundled.first;
  final chime = Ringtone.bundled.last;
  const picked = Ringtone(id: 'content://media/42', title: 'Over the Horizon');

  setUpAll(() {
    registerFallbackValue(MotionSensitivity.low);
    registerFallbackValue(classic);
  });

  setUp(() {
    repository = MockSettingsRepository();
    when(() => repository.sensitivity).thenReturn(MotionSensitivity.medium);
    when(() => repository.ringtone).thenReturn(classic);
    when(() => repository.saveRingtone(any())).thenAnswer((_) async {});
    player = silentRingtonePlayer();
  });

  SettingsBloc build() => SettingsBloc(repository, player: player);

  blocTest<SettingsBloc, SettingsState>(
    'saves a new sensitivity',
    setUp: () =>
        when(() => repository.saveSensitivity(any())).thenAnswer((_) async {}),
    build: build,
    act: (bloc) => bloc.add(const SensitivityChosen(MotionSensitivity.high)),
    expect: () => [
      SettingsState(sensitivity: MotionSensitivity.high, ringtone: classic),
    ],
    verify: (_) =>
        verify(() => repository.saveSensitivity(MotionSensitivity.high)),
  );

  blocTest<SettingsBloc, SettingsState>(
    'reverts and reports when saving fails',
    setUp: () => when(
      () => repository.saveSensitivity(any()),
    ).thenThrow(const StorageWriteException()),
    build: build,
    act: (bloc) => bloc.add(const SensitivityChosen(MotionSensitivity.high)),
    expect: () => [
      SettingsState(sensitivity: MotionSensitivity.high, ringtone: classic),
      SettingsState(
        sensitivity: MotionSensitivity.medium,
        ringtone: classic,
        saveFailed: true,
      ),
    ],
  );

  group('ringtone', () {
    blocTest<SettingsBloc, SettingsState>(
      'choosing a bundled tone previews it once and saves it',
      build: build,
      act: (bloc) => bloc.add(RingtoneChosen(chime)),
      expect: () => [
        SettingsState(sensitivity: MotionSensitivity.medium, ringtone: chime),
      ],
      verify: (_) {
        verify(() => player.play(chime, loop: false)).called(1);
        verify(() => repository.saveRingtone(chime)).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'still saves the choice when the preview cannot play',
      setUp: () => when(
        () => player.play(any(), loop: any(named: 'loop')),
      ).thenThrow(PlatformException(code: 'NOT_FOUND')),
      build: build,
      act: (bloc) => bloc.add(RingtoneChosen(chime)),
      expect: () => [
        SettingsState(sensitivity: MotionSensitivity.medium, ringtone: chime),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'reverts and reports when the tone cannot be saved',
      setUp: () => when(
        () => repository.saveRingtone(any()),
      ).thenThrow(const StorageWriteException()),
      build: build,
      act: (bloc) => bloc.add(RingtoneChosen(chime)),
      expect: () => [
        SettingsState(sensitivity: MotionSensitivity.medium, ringtone: chime),
        SettingsState(
          sensitivity: MotionSensitivity.medium,
          ringtone: classic,
          saveFailed: true,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'saves what the system picker returns',
      setUp: () =>
          when(() => player.pick(any())).thenAnswer((_) async => picked),
      build: build,
      act: (bloc) => bloc.add(const RingtonePickerOpened()),
      expect: () => [
        const SettingsState(
          sensitivity: MotionSensitivity.medium,
          ringtone: picked,
        ),
      ],
      verify: (_) {
        verify(() => player.pick(classic)).called(1);
        verify(() => repository.saveRingtone(picked)).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'keeps the tone when the picker is closed without choosing',
      build: build,
      act: (bloc) => bloc.add(const RingtonePickerOpened()),
      expect: () => <SettingsState>[],
      verify: (_) => verifyNever(() => repository.saveRingtone(any())),
    );

    blocTest<SettingsBloc, SettingsState>(
      'reports a picker that will not open',
      setUp: () => when(
        () => player.pick(any()),
      ).thenThrow(PlatformException(code: 'UNAVAILABLE')),
      build: build,
      act: (bloc) => bloc.add(const RingtonePickerOpened()),
      expect: () => [
        SettingsState(
          sensitivity: MotionSensitivity.medium,
          ringtone: classic,
          pickerFailed: true,
        ),
      ],
    );

    test('closing stops a preview that is still playing', () async {
      await build().close();
      verify(player.stop).called(1);
    });
  });

  test('local repository falls back to medium and round trips', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = LocalSettingsRepository(
      await SharedPreferences.getInstance(),
      userId: 'u1',
    );

    expect(settings.sensitivity, MotionSensitivity.medium);
    await settings.saveSensitivity(MotionSensitivity.low);
    expect(settings.sensitivity, MotionSensitivity.low);
  });

  test('local repository round trips the ringtone', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = LocalSettingsRepository(
      await SharedPreferences.getInstance(),
      userId: 'u1',
    );

    expect(settings.ringtone, isNull);
    await settings.saveRingtone(picked);
    expect(settings.ringtone, picked);
  });

  test('a corrupt stored ringtone falls back to the default', () async {
    SharedPreferences.setMockInitialValues({
      'user:u1:ringtone': '{not json',
      'user:u2:ringtone': '{"id": 3}',
    });
    final prefs = await SharedPreferences.getInstance();

    expect(LocalSettingsRepository(prefs, userId: 'u1').ringtone, isNull);
    expect(LocalSettingsRepository(prefs, userId: 'u2').ringtone, isNull);
  });
}
