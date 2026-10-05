part of 'calls_bloc.dart';

sealed class CallsEvent {
  const CallsEvent();
}

/// Load the history and keep following it.
final class CallsStarted extends CallsEvent {
  const CallsStarted();
}
