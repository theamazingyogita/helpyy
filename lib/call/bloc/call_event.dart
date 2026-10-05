part of 'call_bloc.dart';

sealed class CallEvent {
  const CallEvent();
}

/// Cancel button during the countdown.
final class CallCancelled extends CallEvent {
  const CallCancelled();
}

final class CallAnswered extends CallEvent {
  const CallAnswered();
}

/// Decline while ringing, or End once answered.
final class CallHungUp extends CallEvent {
  const CallHungUp();
}

final class _CountdownTicked extends CallEvent {
  const _CountdownTicked();
}

final class _TalkClockTicked extends CallEvent {
  const _TalkClockTicked();
}
