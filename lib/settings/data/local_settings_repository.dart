import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../ringtone/ringtone.dart';
import '../../storage/storage_write_exception.dart';
import '../motion_sensitivity.dart';
import 'settings_repository.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._prefs, {required String userId})
    : _sensitivityKey = 'user:$userId:motion_sensitivity',
      _ringtoneKey = 'user:$userId:ringtone';

  final SharedPreferences _prefs;
  final String _sensitivityKey;
  final String _ringtoneKey;

  @override
  MotionSensitivity get sensitivity {
    final name = _prefs.getString(_sensitivityKey);
    for (final value in MotionSensitivity.values) {
      if (value.name == name) return value;
    }
    return MotionSensitivity.medium;
  }

  @override
  Future<void> saveSensitivity(MotionSensitivity value) async {
    if (!await _prefs.setString(_sensitivityKey, value.name)) {
      throw const StorageWriteException();
    }
  }

  @override
  Ringtone? get ringtone {
    final raw = _prefs.getString(_ringtoneKey);
    if (raw == null) return null;
    try {
      if (jsonDecode(raw) case {
        'id': final String id,
        'title': final String title,
      }) {
        return Ringtone(id: id, title: title);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  @override
  Future<void> saveRingtone(Ringtone value) async {
    if (!await _prefs.setString(_ringtoneKey, jsonEncode(value.toJson()))) {
      throw const StorageWriteException();
    }
  }
}
