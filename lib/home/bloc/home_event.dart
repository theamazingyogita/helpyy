part of 'home_bloc.dart';

sealed class HomeEvent {
  const HomeEvent();
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeListeningToggled extends HomeEvent {
  const HomeListeningToggled(this.isOn);

  final bool isOn;
}

final class HomeTestCallRequested extends HomeEvent {
  const HomeTestCallRequested(this.pattern);

  final KnockPattern pattern;
}

final class HomeCallEnded extends HomeEvent {
  const HomeCallEnded();
}

final class HomeSignalEditingStarted extends HomeEvent {
  const HomeSignalEditingStarted();
}

final class HomeSignalEditingFinished extends HomeEvent {
  const HomeSignalEditingFinished();
}

final class HomeSignalDeleted extends HomeEvent {
  const HomeSignalDeleted(this.pattern);

  final KnockPattern pattern;
}

final class _HomeKnocksDetected extends HomeEvent {
  const _HomeKnocksDetected(this.gaps);

  final List<int> gaps;
}

final class _HomeSensorFailed extends HomeEvent {
  const _HomeSensorFailed();
}

final class _HomeBackTapped extends HomeEvent {
  const _HomeBackTapped(this.taps);

  final int taps;
}
