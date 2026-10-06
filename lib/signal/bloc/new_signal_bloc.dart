import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../knock/data/pattern_repository.dart';
import '../../knock/knock_detector.dart';
import '../../knock/knock_pattern.dart';
import '../../storage/storage_write_exception.dart';

part 'new_signal_event.dart';
part 'new_signal_state.dart';

class NewSignalBloc extends Bloc<NewSignalEvent, NewSignalState> {
  NewSignalBloc({
    required PatternRepository repository,
    required KnockDetector detector,
    DateTime Function()? now,
    this.isBackTapOnly = false,
  }) : _repository = repository,
       _detector = detector,
       _now = now ?? DateTime.now,
       super(const NewSignalState()) {
    on<NewSignalStarted>(_onStarted);
    on<TriggerKindChosen>(_onTriggerKindChosen);
    on<TapCountChanged>(_onTapCountChanged);
    on<RhythmRetried>(_onRhythmRetried);
    on<TriggerConfirmed>(_onTriggerConfirmed);
    on<CallerStepLeft>(_onCallerStepLeft);
    on<CallDelayChosen>(
      (event, emit) => emit(state.copyWith(delaySeconds: event.seconds)),
    );
    on<SignalSaved>(_onSignalSaved);
    on<_RhythmKnocked>(_onRhythmKnocked);
    on<_RecorderSensorFailed>(_onSensorFailed);
  }

  final bool isBackTapOnly;

  int get minTaps => isBackTapOnly ? 2 : KnockDetector.minKnocks;
  int get maxTaps => isBackTapOnly ? 3 : 8;

  final PatternRepository _repository;
  final KnockDetector _detector;
  final DateTime Function() _now;
  StreamSubscription<List<int>>? _knocks;
  List<KnockPattern> _saved = const [];

  Future<void> _onStarted(
    NewSignalStarted event,
    Emitter<NewSignalState> emit,
  ) async {
    try {
      _saved = await _repository.load();
    } on FormatException {
      _saved = const [];
    }
    final clashes = _clashes(state);
    if (clashes != state.clashes) emit(state.copyWith(clashes: clashes));
  }

  void _onTriggerKindChosen(
    TriggerKindChosen event,
    Emitter<NewSignalState> emit,
  ) {
    if (event.useRhythm == state.useRhythm) return;
    if (event.useRhythm && isBackTapOnly) return;
    _emitChecked(
      state.copyWith(
        useRhythm: event.useRhythm,
        rhythm: const [],
        recordStatus: event.useRhythm
            ? RecordStatus.listening
            : RecordStatus.idle,
      ),
      emit,
    );
    event.useRhythm ? _listen() : _stopListening();
  }

  void _onTapCountChanged(TapCountChanged event, Emitter<NewSignalState> emit) {
    if (event.count < minTaps || event.count > maxTaps) return;
    _emitChecked(state.copyWith(tapCount: event.count), emit);
  }

  void _onRhythmRetried(RhythmRetried event, Emitter<NewSignalState> emit) {
    emit(
      state.copyWith(
        rhythm: const [],
        recordStatus: RecordStatus.listening,
        clashes: false,
      ),
    );
    _listen();
  }

  void _onTriggerConfirmed(
    TriggerConfirmed event,
    Emitter<NewSignalState> emit,
  ) {
    if (!state.canContinue) return;
    _stopListening();
    emit(state.copyWith(step: SignalStep.caller));
  }

  void _onCallerStepLeft(CallerStepLeft event, Emitter<NewSignalState> emit) {
    if (state.step == SignalStep.trigger) return;
    emit(state.copyWith(step: SignalStep.trigger));
    if (state.useRhythm && state.recordStatus != RecordStatus.captured) {
      _listen();
    }
  }

  Future<void> _onSignalSaved(
    SignalSaved event,
    Emitter<NewSignalState> emit,
  ) async {
    final name = event.callerName.trim();
    if (name.isEmpty || !state.canContinue) return;
    emit(state.copyWith(saveStatus: SaveStatus.saving));
    try {
      await _repository.add(_pattern(state, name));
    } on StorageWriteException {
      emit(state.copyWith(saveStatus: SaveStatus.failed));
      return;
    } on FormatException {
      emit(state.copyWith(saveStatus: SaveStatus.failed));
      return;
    }
    emit(state.copyWith(saveStatus: SaveStatus.saved));
  }

  void _onRhythmKnocked(_RhythmKnocked event, Emitter<NewSignalState> emit) {
    if (state.recordStatus != RecordStatus.listening) return;
    _stopListening();
    _emitChecked(
      state.copyWith(rhythm: event.gaps, recordStatus: RecordStatus.captured),
      emit,
    );
  }

  void _onSensorFailed(
    _RecorderSensorFailed event,
    Emitter<NewSignalState> emit,
  ) {
    _knocks = null;
    emit(state.copyWith(recordStatus: RecordStatus.sensorUnavailable));
  }

  void _emitChecked(NewSignalState next, Emitter<NewSignalState> emit) {
    emit(next.copyWith(clashes: _clashes(next)));
  }

  KnockPattern _pattern(NewSignalState state, String callerName) {
    return KnockPattern(
      id: _now().microsecondsSinceEpoch.toString(),
      callerName: callerName,
      knockCount: state.useRhythm ? state.rhythm.length + 1 : state.tapCount,
      rhythm: state.useRhythm ? state.rhythm : null,
      delaySeconds: state.delaySeconds,
    );
  }

  bool _clashes(NewSignalState state) {
    if (state.useRhythm && state.recordStatus != RecordStatus.captured) {
      return false;
    }
    return _saved.any(_pattern(state, '').overlaps);
  }

  void _listen() {
    _knocks ??= _detector.sequences().listen(
      (gaps) => add(_RhythmKnocked(gaps)),
      onError: (Object _) => add(const _RecorderSensorFailed()),
      cancelOnError: true,
    );
  }

  void _stopListening() {
    _knocks?.cancel();
    _knocks = null;
  }

  @override
  Future<void> close() {
    _knocks?.cancel();
    return super.close();
  }
}
