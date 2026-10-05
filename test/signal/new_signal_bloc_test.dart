import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/knock/knock_pattern.dart';
import 'package:helpyy/signal/bloc/new_signal_bloc.dart';
import 'package:helpyy/storage/storage_write_exception.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';
import '../helpers/settle.dart';

void main() {
  const fourTaps = KnockPattern(id: '1', callerName: 'Mom', knockCount: 4);

  late MockPatternRepository repository;
  late MockKnockDetector detector;
  late StreamController<List<int>> knocks;

  setUpAll(() => registerFallbackValue(fourTaps));

  setUp(() {
    repository = MockPatternRepository();
    detector = MockKnockDetector();
    knocks = StreamController<List<int>>.broadcast();
    when(() => detector.sequences()).thenAnswer((_) => knocks.stream);
    when(() => repository.load()).thenAnswer((_) async => [fourTaps]);
  });

  tearDown(() => knocks.close());

  NewSignalBloc build() => NewSignalBloc(
    repository: repository,
    detector: detector,
    now: () => DateTime.fromMicrosecondsSinceEpoch(42),
  );

  blocTest<NewSignalBloc, NewSignalState>(
    'starts on three taps, which is free',
    build: build,
    act: (bloc) => bloc.add(const NewSignalStarted()),
    expect: () => <NewSignalState>[],
    verify: (bloc) => expect(bloc.state.canContinue, isTrue),
  );

  blocTest<NewSignalBloc, NewSignalState>(
    'flags a tap count a saved signal already uses',
    build: build,
    act: (bloc) async {
      bloc.add(const NewSignalStarted());
      await settle();
      bloc.add(const TapCountChanged(4));
    },
    expect: () => [const NewSignalState(tapCount: 4, clashes: true)],
  );

  blocTest<NewSignalBloc, NewSignalState>(
    'keeps the tap count within limits',
    build: build,
    act: (bloc) => bloc
      ..add(const TapCountChanged(2))
      ..add(const TapCountChanged(9)),
    expect: () => <NewSignalState>[],
  );

  group('Back Tap only, on iOS', () {
    NewSignalBloc buildBackTapOnly() => NewSignalBloc(
      repository: repository,
      detector: detector,
      isBackTapOnly: true,
    );

    blocTest<NewSignalBloc, NewSignalState>(
      'allows only a double or triple tap',
      build: buildBackTapOnly,
      act: (bloc) => bloc
        ..add(const TapCountChanged(2))
        ..add(const TapCountChanged(4))
        ..add(const TapCountChanged(1)),
      expect: () => [const NewSignalState(tapCount: 2)],
    );

    blocTest<NewSignalBloc, NewSignalState>(
      'ignores a custom rhythm and never starts recording',
      build: buildBackTapOnly,
      act: (bloc) => bloc.add(const TriggerKindChosen(useRhythm: true)),
      expect: () => <NewSignalState>[],
      verify: (_) => verifyNever(() => detector.sequences()),
    );
  });

  blocTest<NewSignalBloc, NewSignalState>(
    'records a custom rhythm',
    build: build,
    act: (bloc) async {
      bloc.add(const TriggerKindChosen(useRhythm: true));
      await settle();
      knocks.add([200, 600]);
    },
    skip: 1,
    expect: () => [
      const NewSignalState(
        useRhythm: true,
        rhythm: [200, 600],
        recordStatus: RecordStatus.captured,
      ),
    ],
  );

  blocTest<NewSignalBloc, NewSignalState>(
    'cannot continue before a rhythm is recorded',
    build: build,
    act: (bloc) => bloc
      ..add(const TriggerKindChosen(useRhythm: true))
      ..add(const TriggerConfirmed()),
    expect: () => [
      const NewSignalState(
        useRhythm: true,
        recordStatus: RecordStatus.listening,
      ),
    ],
  );

  blocTest<NewSignalBloc, NewSignalState>(
    'reports a missing sensor',
    setUp: () => when(
      () => detector.sequences(),
    ).thenAnswer((_) => Stream.error(UnsupportedError('no sensor'))),
    build: build,
    act: (bloc) => bloc.add(const TriggerKindChosen(useRhythm: true)),
    skip: 1,
    expect: () => [
      const NewSignalState(
        useRhythm: true,
        recordStatus: RecordStatus.sensorUnavailable,
      ),
    ],
  );

  blocTest<NewSignalBloc, NewSignalState>(
    'moves to the caller step and back',
    build: build,
    act: (bloc) => bloc
      ..add(const TriggerConfirmed())
      ..add(const CallerStepLeft())
      ..add(const CallerStepLeft()),
    expect: () => [
      const NewSignalState(step: SignalStep.caller),
      const NewSignalState(),
    ],
  );

  blocTest<NewSignalBloc, NewSignalState>(
    'saves a tap count signal with name and delay',
    setUp: () => when(() => repository.add(any())).thenAnswer((_) async {}),
    build: build,
    act: (bloc) => bloc
      ..add(const CallDelayChosen(10))
      ..add(const SignalSaved('  Maya ')),
    expect: () => [
      const NewSignalState(delaySeconds: 10),
      const NewSignalState(delaySeconds: 10, saveStatus: SaveStatus.saving),
      const NewSignalState(delaySeconds: 10, saveStatus: SaveStatus.saved),
    ],
    verify: (_) => verify(
      () => repository.add(
        const KnockPattern(
          id: '42',
          callerName: 'Maya',
          knockCount: 3,
          delaySeconds: 10,
        ),
      ),
    ).called(1),
  );

  blocTest<NewSignalBloc, NewSignalState>(
    'reports a failed save',
    setUp: () => when(
      () => repository.add(any()),
    ).thenThrow(const StorageWriteException()),
    build: build,
    act: (bloc) => bloc.add(const SignalSaved('Maya')),
    expect: () => [
      const NewSignalState(saveStatus: SaveStatus.saving),
      const NewSignalState(saveStatus: SaveStatus.failed),
    ],
  );

  blocTest<NewSignalBloc, NewSignalState>(
    'does not save without a name',
    build: build,
    act: (bloc) => bloc.add(const SignalSaved('  ')),
    expect: () => <NewSignalState>[],
    verify: (_) => verifyNever(() => repository.add(any())),
  );
}
