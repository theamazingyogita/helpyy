part of 'calls_bloc.dart';

sealed class CallsEvent {
  const CallsEvent();
}

final class CallsStarted extends CallsEvent {
  const CallsStarted();
}
