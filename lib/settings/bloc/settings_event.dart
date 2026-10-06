part of 'settings_bloc.dart';

sealed class SettingsEvent {
  const SettingsEvent();
}

final class SensitivityChosen extends SettingsEvent {
  const SensitivityChosen(this.value);

  final MotionSensitivity value;
}

final class RingtoneChosen extends SettingsEvent {
  const RingtoneChosen(this.ringtone);

  final Ringtone ringtone;
}

final class RingtonePickerOpened extends SettingsEvent {
  const RingtonePickerOpened();
}
