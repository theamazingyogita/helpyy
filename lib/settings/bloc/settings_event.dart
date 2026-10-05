part of 'settings_bloc.dart';

sealed class SettingsEvent {
  const SettingsEvent();
}

final class SensitivityChosen extends SettingsEvent {
  const SensitivityChosen(this.value);

  final MotionSensitivity value;
}

/// One of the bundled tones was tapped, iOS only. It plays once as a preview.
final class RingtoneChosen extends SettingsEvent {
  const RingtoneChosen(this.ringtone);

  final Ringtone ringtone;
}

/// Opens the system ringtone picker, Android only.
final class RingtonePickerOpened extends SettingsEvent {
  const RingtonePickerOpened();
}
