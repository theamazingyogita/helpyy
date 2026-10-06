import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/call/bloc/call_bloc.dart';
import 'package:helpyy/calls/data/call_record.dart';
import 'package:helpyy/ringtone/ringtone.dart';
import 'package:helpyy/storage/storage_write_exception.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

void main() {
  final rangAt = DateTime(2026, 10, 6, 14);
  late MockCallLogRepository log;
  late MockRingtonePlayer ringtones;
  late int rings;
  final chime = Ringtone.bundled.last;

  setUpAll(
    () => registerFallbackValue(
      CallRecord(callerName: '', startedAt: rangAt, answered: false),
    ),
  );

  setUp(() {
    rings = 0;
    log = MockCallLogRepository();
    when(() => log.add(any())).thenAnswer((_) async {});
    ringtones = silentRingtonePlayer();
  });

  CallBloc build({int delay = 0}) => CallBloc(
    callerName: 'Maya',
    delaySeconds: delay,
    log: log,
    ringtones: ringtones,
    ringtone: chime,
    ring: () async => rings++,
    now: () => rangAt,
  );

  test('rings straight away without a delay', () async {
    final bloc = build();
    expect(bloc.state, const CallState(phase: CallPhase.ringing));
    expect(rings, 1);
    verify(() => ringtones.play(chime)).called(1);
    await bloc.close();
  });

  test('closing while ringing stops the ringtone', () async {
    final bloc = build();
    await bloc.close();
    verify(ringtones.stop).called(1);
  });

  test('still rings and vibrates when the ringtone cannot play', () async {
    when(
      () => ringtones.play(any(), loop: any(named: 'loop')),
    ).thenAnswer((_) async => throw PlatformException(code: 'UNAVAILABLE'));
    final bloc = build();
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.phase, CallPhase.ringing);
    expect(rings, 1);
    await bloc.close();
  });

  blocTest<CallBloc, CallState>(
    'counts down before ringing',
    build: () => build(delay: 2),
    wait: const Duration(milliseconds: 2100),
    expect: () => [
      const CallState(phase: CallPhase.countdown, secondsLeft: 1),
      const CallState(phase: CallPhase.ringing),
    ],
    verify: (_) => expect(rings, 1),
  );

  blocTest<CallBloc, CallState>(
    'cancelling the countdown ends without logging',
    build: () => build(delay: 5),
    act: (bloc) => bloc.add(const CallCancelled()),
    expect: () => [const CallState(phase: CallPhase.ended, wasCancelled: true)],
    verify: (_) {
      verifyNever(() => log.add(any()));
      expect(rings, 0);
      verifyNever(() => ringtones.play(any(), loop: any(named: 'loop')));
    },
  );

  blocTest<CallBloc, CallState>(
    'answering starts the talk clock',
    build: build,
    act: (bloc) => bloc.add(const CallAnswered()),
    wait: const Duration(milliseconds: 1100),
    expect: () => [
      const CallState(phase: CallPhase.answered),
      const CallState(phase: CallPhase.answered, elapsed: Duration(seconds: 1)),
    ],
    verify: (_) => verify(ringtones.stop).called(1),
  );

  blocTest<CallBloc, CallState>(
    'declining logs an unanswered call',
    build: build,
    act: (bloc) => bloc.add(const CallHungUp()),
    expect: () => [const CallState(phase: CallPhase.ended)],
    verify: (_) {
      verify(
        () => log.add(
          CallRecord(callerName: 'Maya', startedAt: rangAt, answered: false),
        ),
      ).called(1);
      verify(ringtones.stop).called(1);
    },
  );

  blocTest<CallBloc, CallState>(
    'hanging up an answered call logs it as answered',
    build: build,
    act: (bloc) => bloc
      ..add(const CallAnswered())
      ..add(const CallHungUp()),
    skip: 1,
    expect: () => [const CallState(phase: CallPhase.ended)],
    verify: (_) => verify(
      () => log.add(
        CallRecord(callerName: 'Maya', startedAt: rangAt, answered: true),
      ),
    ).called(1),
  );

  blocTest<CallBloc, CallState>(
    'still ends the call when history cannot be saved',
    setUp: () =>
        when(() => log.add(any())).thenThrow(const StorageWriteException()),
    build: build,
    act: (bloc) => bloc.add(const CallHungUp()),
    expect: () => [
      const CallState(phase: CallPhase.ended, historyFailed: true),
    ],
  );
}
