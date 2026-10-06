part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.sensitivity,
    this.ringtone,
    this.saveFailed = false,
    this.pickerFailed = false,
  });

  final MotionSensitivity sensitivity;

  final Ringtone? ringtone;

  final bool saveFailed;
  final bool pickerFailed;

  SettingsState copyWith({
    MotionSensitivity? sensitivity,
    ValueGetter<Ringtone?>? ringtone,
    bool saveFailed = false,
    bool pickerFailed = false,
  }) {
    return SettingsState(
      sensitivity: sensitivity ?? this.sensitivity,
      ringtone: ringtone != null ? ringtone() : this.ringtone,
      saveFailed: saveFailed,
      pickerFailed: pickerFailed,
    );
  }

  @override
  List<Object?> get props => [sensitivity, ringtone, saveFailed, pickerFailed];
}
