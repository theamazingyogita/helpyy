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

  final int secondsLeft;

  final Duration elapsed;

  final bool historyFailed;

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
