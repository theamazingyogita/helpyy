import '../../ringtone/ringtone.dart';
import '../motion_sensitivity.dart';

abstract interface class SettingsRepository {
  MotionSensitivity get sensitivity;

  Future<void> saveSensitivity(MotionSensitivity value);

  Ringtone? get ringtone;

  Future<void> saveRingtone(Ringtone value);
}
