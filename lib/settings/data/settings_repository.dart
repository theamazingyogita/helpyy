import '../../ringtone/ringtone.dart';
import '../motion_sensitivity.dart';

/// The signed in user's preferences.
abstract interface class SettingsRepository {
  /// Last known value. Read on every accelerometer sample, so it has to be
  /// synchronous. A backend version fetches once at sign in and caches.
  MotionSensitivity get sensitivity;

  /// Throws [StorageWriteException].
  Future<void> saveSensitivity(MotionSensitivity value);

  /// Null until the user picks one, which rings the default tone.
  Ringtone? get ringtone;

  /// Throws [StorageWriteException].
  Future<void> saveRingtone(Ringtone value);
}
