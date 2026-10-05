part of 'intro_bloc.dart';

sealed class IntroEvent {
  const IntroEvent();
}

final class IntroFinished extends IntroEvent {
  const IntroFinished();
}
