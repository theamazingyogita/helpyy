part of 'home_bloc.dart';

sealed class HomeEvent {
  const HomeEvent();
}

/// Load saved signals. Also used to retry after a failed load.
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

/// The new signal screen opened. It uses the sensor itself, and a rhythm
/// being recorded would otherwise set off a call for a matching signal.
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

/// A Back Tap shortcut ran, see BackTapShortcuts.
final class _HomeBackTapped extends HomeEvent {
  const _HomeBackTapped(this.taps);

  final int taps;
}
