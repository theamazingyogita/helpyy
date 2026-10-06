import 'package:shared_preferences/shared_preferences.dart';

import '../../storage/storage_write_exception.dart';

class IntroRepository {
  IntroRepository(this._prefs);

  static const _key = 'has_seen_intro';

  final SharedPreferences _prefs;

  bool get hasSeenIntro => _prefs.getBool(_key) ?? false;

  Future<void> markSeen() async {
    if (!await _prefs.setBool(_key, true)) {
      throw const StorageWriteException();
    }
  }
}
