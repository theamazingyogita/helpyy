import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../background/background_listening.dart';
import '../../knock/back_tap_shortcuts.dart';
import '../../knock/data/pattern_repository.dart';
import '../../knock/knock_detector.dart';
import '../../knock/knock_pattern.dart';
import '../../storage/storage_write_exception.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required PatternRepository repository,
    required KnockDetector detector,
    required BackgroundListening background,
    required BackTapShortcuts backTap,
  }) : _repository = repository,
       _detector = detector,
       _background = background,
       super(const HomeState()) {
    on<HomeStarted>((_, emit) => _load(emit));
    on<HomeListeningToggled>(_onListeningToggled);
    on<HomeTestCallRequested>((event, emit) => _ring(event.pattern, emit));
    on<HomeCallEnded>(_onCallEnded);
    on<HomeSignalEditingStarted>((_, _) {
      _isEditing = true;
      _stopListening();
    });
    on<HomeSignalEditingFinished>(_onSignalEditingFinished);
    on<HomeSignalDeleted>(_onSignalDeleted);
    on<_HomeKnocksDetected>(_onKnocksDetected);
    on<_HomeSensorFailed>(_onSensorFailed);
    on<_HomeBackTapped>(_onBackTapped);

    _backTaps = backTap.taps().listen((taps) => add(_HomeBackTapped(taps)));
  }

  final PatternRepository _repository;
  final KnockDetector _detector;
  final BackgroundListening _background;
  StreamSubscription<List<int>>? _knocks;
  late final StreamSubscription<int> _backTaps;
  var _isEditing = false;

  int? _pendingBackTap;

  Future<void> _load(Emitter<HomeState> emit) async {
    try {
      final patterns = await _repository.load();
      emit(
        state.copyWith(
          status: HomeStatus.ready,
          patterns: patterns,
          isListening: state.isListening && patterns.isNotEmpty,
        ),
      );
      if (_pendingBackTap case final taps?) {
        _pendingBackTap = null;
        _ringForBackTap(taps, emit);
      }
    } on FormatException {
      emit(state.copyWith(status: HomeStatus.loadFailed, isListening: false));
    }
  }

  void _onListeningToggled(
    HomeListeningToggled event,
    Emitter<HomeState> emit,
  ) {
    final isListening = event.isOn && state.patterns.isNotEmpty;
    emit(state.copyWith(status: HomeStatus.ready, isListening: isListening));
    if (event.isOn && !isListening) {
      emit(state.copyWith(status: HomeStatus.noSignals));
    }
    isListening ? _listen() : _stopListening();
  }

  void _onCallEnded(HomeCallEnded event, Emitter<HomeState> emit) {
    emit(state.copyWith(incomingCall: () => null));
    if (state.isListening) _listen();
  }

  Future<void> _onSignalEditingFinished(
    HomeSignalEditingFinished event,
    Emitter<HomeState> emit,
  ) async {
    _isEditing = false;
    await _load(emit);
    if (state.isListening) _listen();
  }

  Future<void> _onSignalDeleted(
    HomeSignalDeleted event,
    Emitter<HomeState> emit,
  ) async {
    final remaining = [
      for (final p in state.patterns)
        if (p.id != event.pattern.id) p,
    ];
    try {
      await _repository.save(remaining);
    } on StorageWriteException {
      emit(state.copyWith(status: HomeStatus.deleteFailed));
      return;
    }
    final isListening = state.isListening && remaining.isNotEmpty;
    emit(
      state.copyWith(
        status: HomeStatus.ready,
        patterns: remaining,
        isListening: isListening,
      ),
    );
    if (!isListening) _stopListening();
  }

  void _onKnocksDetected(_HomeKnocksDetected event, Emitter<HomeState> emit) {
    for (final pattern in state.patterns) {
      if (pattern.matches(event.gaps)) {
        _ring(pattern, emit);
        return;
      }
    }
  }

  void _onSensorFailed(_HomeSensorFailed event, Emitter<HomeState> emit) {
    _knocks = null;
    emit(
      state.copyWith(status: HomeStatus.sensorUnavailable, isListening: false),
    );
  }

  void _onBackTapped(_HomeBackTapped event, Emitter<HomeState> emit) {
    if (state.status == HomeStatus.loading) {
      _pendingBackTap = event.taps;
      return;
    }
    _ringForBackTap(event.taps, emit);
  }

  void _ringForBackTap(int taps, Emitter<HomeState> emit) {
    if (state.incomingCall != null || _isEditing) return;
    for (final pattern in state.patterns) {
      if (pattern.rhythm == null && pattern.knockCount == taps) {
        _ring(pattern, emit);
        return;
      }
    }
    emit(state.copyWith(status: HomeStatus.ready));
    emit(state.copyWith(status: HomeStatus.noBackTapSignal));
  }

  void _ring(KnockPattern pattern, Emitter<HomeState> emit) {
    _stopListening();
    emit(state.copyWith(incomingCall: () => pattern));
  }

  void _listen() {
    _knocks ??= _detector.sequences().listen(
      (gaps) => add(_HomeKnocksDetected(gaps)),
      onError: (Object _) => add(const _HomeSensorFailed()),
      cancelOnError: true,
    );
  }

  void _stopListening() {
    _knocks?.cancel();
    _knocks = null;
  }

  @override
  void onChange(Change<HomeState> change) {
    super.onChange(change);
    final before = change.currentState;
    final after = change.nextState;
    if (before.isListening != after.isListening) {
      after.isListening ? _background.start() : _background.stop();
    }
    if (after.incomingCall != before.incomingCall) {
      switch (after.incomingCall) {
        case final pattern?:
          _background.showIncomingCall(pattern.callerName);
        case null:
          _background.endIncomingCall();
      }
    }
  }

  @override
  Future<void> close() {
    _knocks?.cancel();
    _backTaps.cancel();
    if (state.isListening) _background.stop();
    return super.close();
  }
}
