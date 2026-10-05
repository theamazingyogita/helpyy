part of 'call_bloc.dart';

enum CallPhase { countdown, ringing, answered, ended }

class CallState extends Equatable {
  const CallState({
    required this.phase,
    this.secondsLeft = 0,
    this.elapsed = Duration.zero,
    this.historyFailed = false,
    this.wasCancelled = false,
  });

  final CallPhase phase;

  /// Seconds until the phone rings, while counting down.
  final int secondsLeft;

  /// Talk time once answered.
  final Duration elapsed;

  final bool historyFailed;

  /// Ended during the countdown, so there was never a call.
  final bool wasCancelled;

  @override
  List<Object> get props => [
    phase,
    secondsLeft,
    elapsed,
    historyFailed,
    wasCancelled,
  ];
}
