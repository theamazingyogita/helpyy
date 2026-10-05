import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../storage/storage_write_exception.dart';
import '../knock_pattern.dart';
import 'pattern_repository.dart';

class LocalPatternRepository implements PatternRepository {
  LocalPatternRepository(this._prefs, {required String userId})
    : _key = 'user:$userId:knock_patterns';

  final SharedPreferences _prefs;
  final String _key;

  @override
  Future<List<KnockPattern>> load() async => [
    for (final raw in _prefs.getStringList(_key) ?? const <String>[])
      KnockPattern.fromJson(jsonDecode(raw)),
  ];

  @override
  Future<void> save(List<KnockPattern> patterns) async {
    final saved = await _prefs.setStringList(_key, [
      for (final pattern in patterns) jsonEncode(pattern.toJson()),
    ]);
    if (!saved) throw const StorageWriteException();
  }

  @override
  Future<void> add(KnockPattern pattern) async =>
      save([...await load(), pattern]);
}
