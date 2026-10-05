import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/home/bloc/home_bloc.dart';
import 'package:helpyy/knock/knock_pattern.dart';
import 'package:helpyy/storage/storage_write_exception.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';
import '../helpers/settle.dart';

void main() {
  const mom = KnockPattern(
    id: '1',
    callerName: 'Mom',
    knockCount: 3,
    rhythm: [300, 300],
  );
  const boss = KnockPattern(id: '2', callerName: 'Boss', knockCount: 4);
  const ready = HomeState(status: HomeStatus.ready, patterns: [mom, boss]);
  const listening = HomeState(
    status: HomeStatus.ready,
    patterns: [mom, boss],
    isListening: true,
  );

  late MockPatternRepository repository;
  late MockKnockDetector detector;
  late StreamController<List<int>> knocks;
  late MockBackgroundListening background;
  late MockBackTapShortcuts backTap;
  late StreamController<int> backTaps;

  setUp(() {
    repository = MockPatternRepository();
    detector = MockKnockDetector();
    knocks = StreamController<List<int>>.broadcast();
    when(() => detector.sequences()).thenAnswer((_) => knocks.stream);
    background = quietBackgroundListening();
    backTap = MockBackTapShortcuts();
    backTaps = StreamController<int>.broadcast();
    when(backTap.taps).thenAnswer((_) => backTaps.stream);
  });

  tearDown(() {
    knocks.close();
    backTaps.close();
  });

  HomeBloc build() => HomeBloc(
    repository: repository,
    detector: detector,
    background: background,
    backTap: backTap,
  );

  group('HomeStarted', () {
    blocTest<HomeBloc, HomeState>(
      'loads saved signals',
      setUp: () =>
          when(() => repository.load()).thenAnswer((_) async => [mom, boss]),
      build: build,
      act: (bloc) => bloc.add(const HomeStarted()),
      expect: () => [ready],
    );

    blocTest<HomeBloc, HomeState>(
      'reports unreadable storage',
      setUp: () =>
          when(() => repository.load()).thenThrow(const FormatException('bad')),
      build: build,
      act: (bloc) => bloc.add(const HomeStarted()),
      expect: () => [const HomeState(status: HomeStatus.loadFailed)],
    );
  });

  group('listening', () {
    blocTest<HomeBloc, HomeState>(
      'rings the caller whose signal was tapped',
      build: build,
      seed: () => ready,
      act: (bloc) async {
        bloc.add(const HomeListeningToggled(true));
        await settle();
        knocks.add([210, 760, 400]);
      },
      expect: () => [
        listening,
        const HomeState(
          status: HomeStatus.ready,
          patterns: [mom, boss],
          isListening: true,
          incomingCall: boss,
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'ignores taps that match no signal',
      build: build,
      seed: () => ready,
      act: (bloc) async {
        bloc.add(const HomeListeningToggled(true));
        await settle();
        knocks.add([1000, 1000, 1000, 1000]);
      },
      expect: () => [listening],
    );

    blocTest<HomeBloc, HomeState>(
      'does not switch on without signals and says why every time',
      build: build,
      seed: () => const HomeState(status: HomeStatus.ready),
      act: (bloc) => bloc
        ..add(const HomeListeningToggled(true))
        ..add(const HomeListeningToggled(true)),
      expect: () => const [
        HomeState(status: HomeStatus.noSignals),
        HomeState(status: HomeStatus.ready),
        HomeState(status: HomeStatus.noSignals),
      ],
      verify: (_) => verifyNever(() => detector.sequences()),
    );

    blocTest<HomeBloc, HomeState>(
      'switches off and reports a missing sensor',
      setUp: () => when(
        () => detector.sequences(),
      ).thenAnswer((_) => Stream.error(UnsupportedError('no sensor'))),
      build: build,
      seed: () => ready,
      act: (bloc) => bloc.add(const HomeListeningToggled(true)),
      expect: () => [
        listening,
        const HomeState(
          status: HomeStatus.sensorUnavailable,
          patterns: [mom, boss],
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'stops listening while a signal is being added',
      build: build,
      seed: () => ready,
      act: (bloc) async {
        bloc
          ..add(const HomeListeningToggled(true))
          ..add(const HomeSignalEditingStarted());
        await settle();
        knocks.add([300, 300]);
      },
      expect: () => [listening],
    );

    blocTest<HomeBloc, HomeState>(
      'listens again after the call ends',
      build: build,
      seed: () => ready,
      act: (bloc) async {
        bloc.add(const HomeListeningToggled(true));
        await settle();
        knocks.add([300, 300]);
        await settle();
        bloc.add(const HomeCallEnded());
        await settle();
        knocks.add([200, 800, 300]);
      },
      skip: 1,
      expect: () => [
        const HomeState(
          status: HomeStatus.ready,
          patterns: [mom, boss],
          isListening: true,
          incomingCall: mom,
        ),
        listening,
        const HomeState(
          status: HomeStatus.ready,
          patterns: [mom, boss],
          isListening: true,
          incomingCall: boss,
        ),
      ],
    );
  });

  blocTest<HomeBloc, HomeState>(
    'a test call rings that signal',
    build: build,
    seed: () => ready,
    act: (bloc) => bloc.add(const HomeTestCallRequested(mom)),
    expect: () => [
      const HomeState(
        status: HomeStatus.ready,
        patterns: [mom, boss],
        incomingCall: mom,
      ),
    ],
  );

  group('HomeSignalDeleted', () {
    blocTest<HomeBloc, HomeState>(
      'removes the signal',
      setUp: () => when(() => repository.save(any())).thenAnswer((_) async {}),
      build: build,
      seed: () => ready,
      act: (bloc) => bloc.add(const HomeSignalDeleted(mom)),
      expect: () => [
        const HomeState(status: HomeStatus.ready, patterns: [boss]),
      ],
      verify: (_) => verify(() => repository.save([boss])).called(1),
    );

    blocTest<HomeBloc, HomeState>(
      'keeps the signal and reports when saving fails',
      setUp: () => when(
        () => repository.save(any()),
      ).thenThrow(const StorageWriteException()),
      build: build,
      seed: () => ready,
      act: (bloc) => bloc.add(const HomeSignalDeleted(mom)),
      expect: () => [
        const HomeState(status: HomeStatus.deleteFailed, patterns: [mom, boss]),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'switches listening off when the last signal goes',
      setUp: () => when(() => repository.save(any())).thenAnswer((_) async {}),
      build: build,
      seed: () => const HomeState(
        status: HomeStatus.ready,
        patterns: [mom],
        isListening: true,
      ),
      act: (bloc) => bloc.add(const HomeSignalDeleted(mom)),
      expect: () => [const HomeState(status: HomeStatus.ready)],
    );
  });

  group('background listening', () {
    blocTest<HomeBloc, HomeState>(
      'starts with the switch and stops with it',
      build: build,
      seed: () => ready,
      act: (bloc) => bloc
        ..add(const HomeListeningToggled(true))
        ..add(const HomeListeningToggled(false)),
      verify: (_) {
        verify(background.start).called(1);
        verify(background.stop).called(1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'brings the call up over other apps and clears it when it ends',
      build: build,
      seed: () => ready,
      act: (bloc) => bloc
        ..add(const HomeTestCallRequested(boss))
        ..add(const HomeCallEnded()),
      verify: (_) {
        verify(() => background.showIncomingCall('Boss')).called(1);
        verify(background.endIncomingCall).called(1);
      },
    );

    test('closing while listening stops the service', () async {
      final bloc = build()..add(const HomeListeningToggled(true));
      bloc.emit(listening);
      await bloc.close();
      verify(background.stop).called(1);
    });
  });

  group('Back Tap', () {
    const dad = KnockPattern(id: '3', callerName: 'Dad', knockCount: 3);
    const withDad = HomeState(status: HomeStatus.ready, patterns: [mom, dad]);

    blocTest<HomeBloc, HomeState>(
      'rings the tap count signal with that many taps, switch off or not',
      build: build,
      seed: () => withDad,
      act: (_) => backTaps.add(3),
      expect: () => [
        const HomeState(
          status: HomeStatus.ready,
          patterns: [mom, dad],
          incomingCall: dad,
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'says so when no tap count signal uses it',
      build: build,
      seed: () => withDad,
      act: (_) => backTaps.add(2),
      expect: () => [
        const HomeState(
          status: HomeStatus.noBackTapSignal,
          patterns: [mom, dad],
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'a tap that launched the app rings once the signals load',
      setUp: () =>
          when(() => repository.load()).thenAnswer((_) async => [mom, dad]),
      build: build,
      act: (bloc) async {
        backTaps.add(3);
        await settle();
        bloc.add(const HomeStarted());
      },
      expect: () => [
        withDad,
        const HomeState(
          status: HomeStatus.ready,
          patterns: [mom, dad],
          incomingCall: dad,
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'is ignored while a call is already up',
      build: build,
      seed: () => const HomeState(
        status: HomeStatus.ready,
        patterns: [mom, dad],
        incomingCall: mom,
      ),
      act: (_) => backTaps.add(3),
      expect: () => <HomeState>[],
    );

    blocTest<HomeBloc, HomeState>(
      'is ignored while a signal is being added',
      build: build,
      seed: () => withDad,
      act: (bloc) async {
        bloc.add(const HomeSignalEditingStarted());
        await settle();
        backTaps.add(3);
      },
      expect: () => <HomeState>[],
    );
  });
}
