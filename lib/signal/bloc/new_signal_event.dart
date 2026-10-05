part of 'new_signal_bloc.dart';

sealed class NewSignalEvent {
  const NewSignalEvent();
}

/// Load saved signals so clashes can be spotted.
final class NewSignalStarted extends NewSignalEvent {
  const NewSignalStarted();
}

final class TriggerKindChosen extends NewSignalEvent {
  const TriggerKindChosen({required this.useRhythm});

  final bool useRhythm;
}

final class TapCountChanged extends NewSignalEvent {
  const TapCountChanged(this.count);

  final int count;
}

final class RhythmRetried extends NewSignalEvent {
  const RhythmRetried();
}

final class TriggerConfirmed extends NewSignalEvent {
  const TriggerConfirmed();
}

/// Back from the caller step to the trigger step.
final class CallerStepLeft extends NewSignalEvent {
  const CallerStepLeft();
}

final class CallDelayChosen extends NewSignalEvent {
  const CallDelayChosen(this.seconds);

  final int seconds;
}

final class SignalSaved extends NewSignalEvent {
  const SignalSaved(this.callerName);

  final String callerName;
}

final class _RhythmKnocked extends NewSignalEvent {
  const _RhythmKnocked(this.gaps);

  final List<int> gaps;
}

final class _RecorderSensorFailed extends NewSignalEvent {
  const _RecorderSensorFailed();
}
