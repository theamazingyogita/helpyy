import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../calls/data/call_log_repository.dart';
import '../../calls/data/call_record.dart';
import '../../ringtone/ringtone.dart';
import '../../ringtone/ringtone_player.dart';
import '../../storage/storage_write_exception.dart';

part 'call_event.dart';
part 'call_state.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  CallBloc({
    required String callerName,
    required int delaySeconds,
    required CallLogRepository log,
    required RingtonePlayer ringtones,
    Ringtone? ringtone,
    Future<void> Function()? ring,
    DateTime Function()? now,
  }) : _callerName = callerName,
       _log = log,
       _ringtones = ringtones,
       _ringtone = ringtone,
       _ring = ring ?? HapticFeedback.vibrate,
       _now = now ?? DateTime.now,
       super(
         delaySeconds > 0
             ? CallState(phase: CallPhase.countdown, secondsLeft: delaySeconds)
             : const CallState(phase: CallPhase.ringing),
       ) {
    on<CallCancelled>(_onCancelled);
    on<CallAnswered>(_onAnswered);
    on<CallHungUp>(_onHungUp);
    on<_CountdownTicked>(_onCountdownTicked);
    on<_TalkClockTicked>(
      (_, emit) => emit(
        CallState(
          phase: CallPhase.answered,
          elapsed: state.elapsed + const Duration(seconds: 1),
        ),
      ),
    );

    if (delaySeconds > 0) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => add(const _CountdownTicked()),
      );
    } else {
      _startRinging();
    }
  }

  final String _callerName;
  final CallLogRepository _log;
  final RingtonePlayer _ringtones;
  final Ringtone? _ringtone;

  /// Vibrates once.
  final Future<void> Function() _ring;
  final DateTime Function() _now;
  Timer? _ticker;
  Timer? _ringer;
  DateTime? _rangAt;

  void _onCancelled(CallCancelled event, Emitter<CallState> emit) {
    if (state.phase != CallPhase.countdown) return;
    _ticker?.cancel();
    emit(const CallState(phase: CallPhase.ended, wasCancelled: true));
  }

  void _onAnswered(CallAnswered event, Emitter<CallState> emit) {
    if (state.phase != CallPhase.ringing) return;
    _stopRinging();
    emit(const CallState(phase: CallPhase.answered));
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const _TalkClockTicked()),
    );
  }

  Future<void> _onHungUp(CallHungUp event, Emitter<CallState> emit) async {
    final rangAt = _rangAt;
    if (rangAt == null || state.phase == CallPhase.ended) return;
    _stopRinging();
    _ticker?.cancel();
    final ended = state;
    var historyFailed = false;
    try {
      await _log.add(
        CallRecord(
          callerName: _callerName,
          startedAt: rangAt,
          answered: ended.phase == CallPhase.answered,
          talkTime: ended.elapsed,
        ),
      );
    } on StorageWriteException {
      historyFailed = true;
    }
    emit(
      CallState(
        phase: CallPhase.ended,
        elapsed: ended.elapsed,
        historyFailed: historyFailed,
      ),
    );
  }

  void _onCountdownTicked(_CountdownTicked event, Emitter<CallState> emit) {
    if (state.phase != CallPhase.countdown) return;
    final left = state.secondsLeft - 1;
    if (left > 0) {
      emit(CallState(phase: CallPhase.countdown, secondsLeft: left));
      return;
    }
    _ticker?.cancel();
    emit(const CallState(phase: CallPhase.ringing));
    _startRinging();
  }

  void _startRinging() {
    _rangAt = _now();
    _ring();
    _ringer = Timer.periodic(const Duration(seconds: 2), (_) => _ring());
    unawaited(_playRingtone());
  }

  Future<void> _playRingtone() async {
    try {
      await _ringtones.play(_ringtone);
    } on PlatformException {
      // The phone still vibrates. A silent call is better than no call.
    }
  }

  void _stopRinging() {
    _ringer?.cancel();
    _ringer = null;
    unawaited(_stopRingtone());
  }

  Future<void> _stopRingtone() async {
    try {
      await _ringtones.stop();
    } on PlatformException {
      // Nothing was playing.
    }
  }

  @override
  Future<void> close() {
    if (_ringer != null) _stopRinging();
    _ticker?.cancel();
    return super.close();
  }
}
